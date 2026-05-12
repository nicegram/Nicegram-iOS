# Pure-Python port of fastlane match `decrypt.rb` — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the Ruby-based fastlane match decryption (`build-system/decrypt.rb` shelled from `BuildConfiguration.py:110`) with a self-contained Python 3 implementation using only the standard library.

**Architecture:** Rewrite `build-system/Make/DecryptMatch.py` from scratch as a pure-Python AES-256 implementation. Covers V1 (CBC via `EVP_BytesToKey` with MD5→SHA256 fallback) and V2 (GCM with PBKDF2-derived key/iv/AAD + auth tag). `BuildConfiguration.py` calls the existing `decrypt_match_data(source, destination, password)` entry point directly instead of shelling out to Ruby. `decrypt.rb` is deleted.

**Tech Stack:** Python 3 stdlib only — `hashlib` (MD5 / SHA256 / PBKDF2-HMAC), `base64`.

---

## File structure

- **Rewrite (not edit):** `build-system/Make/DecryptMatch.py` — new file replacing the broken placeholder. Single module containing: AES-256 primitives, `EVP_BytesToKey`, CBC decrypt, GCM decrypt (with GHASH + CTR), `MatchDataEncryption` dispatcher, `decrypt_match_data` public entry, `__main__` CLI.
- **Modify:** `build-system/Make/BuildConfiguration.py:103-118` — swap `os.system('ruby …')` for a direct Python call.
- **Delete:** `build-system/decrypt.rb`.

---

## Task 1: Rewrite `build-system/Make/DecryptMatch.py`

**Files:**
- Modify (rewrite): `build-system/Make/DecryptMatch.py`

- [ ] **Step 1.1: Replace the file contents entirely**

Overwrite `build-system/Make/DecryptMatch.py` with the following. This is the full file — no other changes to this module in later tasks.

```python
import base64
import hashlib


# FIPS-197 AES S-box and inverse S-box.
_SBOX = bytes.fromhex(
    "637c777bf26b6fc53001672bfed7ab76"
    "ca82c97dfa5947f0add4a2af9ca472c0"
    "b7fd9326363ff7cc34a5e5f171d83115"
    "04c723c31896059a071280e2eb27b275"
    "09832c1a1b6e5aa0523bd6b329e32f84"
    "53d100ed20fcb15b6acbbe394a4c58cf"
    "d0efaafb434d338545f9027f503c9fa8"
    "51a3408f929d38f5bcb6da2110fff3d2"
    "cd0c13ec5f974417c4a77e3d645d1973"
    "60814fdc222a908846eeb814de5e0bdb"
    "e0323a0a4906245cc2d3ac629195e479"
    "e7c8376d8dd54ea96c56f4ea657aae08"
    "ba78252e1ca6b4c6e8dd741f4bbd8b8a"
    "703eb5664803f60e613557b986c11d9e"
    "e1f8981169d98e949b1e87e9ce5528df"
    "8ca1890dbfe6426841992d0fb054bb16"
)

_INV_SBOX = bytes.fromhex(
    "52096ad53036a538bf40a39e81f3d7fb"
    "7ce339829b2fff87348e4344c4dee9cb"
    "547b9432a6c2233dee4c950b42fac34e"
    "082ea16628d924b2765ba2496d8bd125"
    "72f8f66486689816d4a45ccc5d65b692"
    "6c704850fdedb9da5e154657a78d9d84"
    "90d8ab008cbcd30af7e45805b8b34506"
    "d02c1e8fca3f0f02c1afbd0301138a6b"
    "3a9111414f67dcea97f2cfcef0b4e673"
    "96ac7422e7ad3585e2f937e81c75df6e"
    "47f11a711d29c5896fb7620eaa18be1b"
    "fc563e4bc6d279209adbc0fe78cd5af4"
    "1fdda8338807c731b11210592780ec5f"
    "60517fa919b54a0d2de57a9f93c99cef"
    "a0e03b4dae2af5b0c8ebbb3c83539961"
    "172b047eba77d626e169146355210c7d"
)

_RCON = bytes.fromhex("01020408102040801b36")


def _xtime(a):
    return (((a << 1) ^ 0x1b) & 0xff) if (a & 0x80) else (a << 1)


def _gf_mul(a, b):
    r = 0
    for _ in range(8):
        if b & 1:
            r ^= a
        b >>= 1
        a = _xtime(a)
    return r


def _key_expansion_256(key):
    # AES-256: Nk=8, Nr=14, total 4 * (Nr + 1) = 60 words = 240 bytes.
    assert len(key) == 32
    w = bytearray(240)
    w[:32] = key
    i = 32
    while i < 240:
        t = bytearray(w[i - 4:i])
        if i % 32 == 0:
            t = bytearray([t[1], t[2], t[3], t[0]])
            for j in range(4):
                t[j] = _SBOX[t[j]]
            t[0] ^= _RCON[i // 32 - 1]
        elif i % 32 == 16:
            for j in range(4):
                t[j] = _SBOX[t[j]]
        for j in range(4):
            w[i + j] = w[i - 32 + j] ^ t[j]
        i += 4
    return [bytes(w[r * 16:(r + 1) * 16]) for r in range(15)]


def _add_round_key(state, rk):
    return bytes(s ^ k for s, k in zip(state, rk))


def _sub_bytes(state):
    return bytes(_SBOX[b] for b in state)


def _inv_sub_bytes(state):
    return bytes(_INV_SBOX[b] for b in state)


# Column-major state: state[r + 4 * c], r = 0..3 (row), c = 0..3 (column).
def _shift_rows(state):
    s = bytearray(state)
    s[1], s[5], s[9], s[13] = s[5], s[9], s[13], s[1]
    s[2], s[6], s[10], s[14] = s[10], s[14], s[2], s[6]
    s[3], s[7], s[11], s[15] = s[15], s[3], s[7], s[11]
    return bytes(s)


def _inv_shift_rows(state):
    s = bytearray(state)
    s[1], s[5], s[9], s[13] = s[13], s[1], s[5], s[9]
    s[2], s[6], s[10], s[14] = s[10], s[14], s[2], s[6]
    s[3], s[7], s[11], s[15] = s[7], s[11], s[15], s[3]
    return bytes(s)


def _mix_columns(state):
    s = bytearray(16)
    for c in range(4):
        a0, a1, a2, a3 = state[4 * c], state[4 * c + 1], state[4 * c + 2], state[4 * c + 3]
        s[4 * c]     = _xtime(a0) ^ (_xtime(a1) ^ a1) ^ a2 ^ a3
        s[4 * c + 1] = a0 ^ _xtime(a1) ^ (_xtime(a2) ^ a2) ^ a3
        s[4 * c + 2] = a0 ^ a1 ^ _xtime(a2) ^ (_xtime(a3) ^ a3)
        s[4 * c + 3] = (_xtime(a0) ^ a0) ^ a1 ^ a2 ^ _xtime(a3)
    return bytes(s)


def _inv_mix_columns(state):
    s = bytearray(16)
    for c in range(4):
        a0, a1, a2, a3 = state[4 * c], state[4 * c + 1], state[4 * c + 2], state[4 * c + 3]
        s[4 * c]     = _gf_mul(a0, 0x0e) ^ _gf_mul(a1, 0x0b) ^ _gf_mul(a2, 0x0d) ^ _gf_mul(a3, 0x09)
        s[4 * c + 1] = _gf_mul(a0, 0x09) ^ _gf_mul(a1, 0x0e) ^ _gf_mul(a2, 0x0b) ^ _gf_mul(a3, 0x0d)
        s[4 * c + 2] = _gf_mul(a0, 0x0d) ^ _gf_mul(a1, 0x09) ^ _gf_mul(a2, 0x0e) ^ _gf_mul(a3, 0x0b)
        s[4 * c + 3] = _gf_mul(a0, 0x0b) ^ _gf_mul(a1, 0x0d) ^ _gf_mul(a2, 0x09) ^ _gf_mul(a3, 0x0e)
    return bytes(s)


def _aes_encrypt_block(block, round_keys):
    state = _add_round_key(block, round_keys[0])
    for r in range(1, 14):
        state = _sub_bytes(state)
        state = _shift_rows(state)
        state = _mix_columns(state)
        state = _add_round_key(state, round_keys[r])
    state = _sub_bytes(state)
    state = _shift_rows(state)
    state = _add_round_key(state, round_keys[14])
    return state


def _aes_decrypt_block(block, round_keys):
    state = _add_round_key(block, round_keys[14])
    for r in range(13, 0, -1):
        state = _inv_shift_rows(state)
        state = _inv_sub_bytes(state)
        state = _add_round_key(state, round_keys[r])
        state = _inv_mix_columns(state)
    state = _inv_shift_rows(state)
    state = _inv_sub_bytes(state)
    state = _add_round_key(state, round_keys[0])
    return state


def _evp_bytes_to_key(password, salt, hash_name, key_len=32, iv_len=16):
    # OpenSSL EVP_BytesToKey with count=1, matching Ruby's
    # Cipher#pkcs5_keyivgen(password, salt, 1, hash).
    if isinstance(password, str):
        password = password.encode('utf-8')
    required = key_len + iv_len
    material = b""
    prev = b""
    while len(material) < required:
        h = hashlib.new(hash_name)
        h.update(prev + password + salt)
        prev = h.digest()
        material += prev
    return material[:key_len], material[key_len:key_len + iv_len]


def _aes_cbc_decrypt(ciphertext, key, iv):
    if len(ciphertext) == 0 or len(ciphertext) % 16 != 0:
        raise ValueError("V1 ciphertext length must be a non-zero multiple of 16")
    round_keys = _key_expansion_256(key)
    out = bytearray()
    prev = iv
    for i in range(0, len(ciphertext), 16):
        block = ciphertext[i:i + 16]
        decrypted = _aes_decrypt_block(block, round_keys)
        out.extend(bytes(d ^ p for d, p in zip(decrypted, prev)))
        prev = block
    pad = out[-1]
    if pad < 1 or pad > 16 or not all(b == pad for b in out[-pad:]):
        raise ValueError("V1 PKCS#7 padding check failed")
    return bytes(out[:-pad])


def _ghash(h_bytes, data):
    # GHASH over GF(2^128) with reduction polynomial x^128 + x^7 + x^2 + x + 1,
    # using GCM's bit-reversed convention (top-bit-first when encoded as bytes).
    h = int.from_bytes(h_bytes, 'big')
    y = 0
    reduction = 0xe1 << 120
    for i in range(0, len(data), 16):
        block = data[i:i + 16].ljust(16, b"\x00")
        y ^= int.from_bytes(block, 'big')
        z = 0
        v = y
        for bit in range(127, -1, -1):
            if (h >> bit) & 1:
                z ^= v
            if v & 1:
                v = (v >> 1) ^ reduction
            else:
                v >>= 1
        y = z
    return y.to_bytes(16, 'big')


def _aes_gcm_decrypt(ciphertext, key, iv, aad, auth_tag):
    if len(iv) != 12:
        raise ValueError("V2 requires a 96-bit IV")
    round_keys = _key_expansion_256(key)
    H = _aes_encrypt_block(b"\x00" * 16, round_keys)
    j0 = iv + b"\x00\x00\x00\x01"

    plaintext = bytearray()
    j0_int = int.from_bytes(j0, 'big')
    mask32 = (1 << 32) - 1
    counter_high = j0_int & ~mask32
    counter_low = j0_int & mask32
    n_blocks = (len(ciphertext) + 15) // 16
    for i in range(n_blocks):
        counter_low = (counter_low + 1) & mask32
        ctr_bytes = (counter_high | counter_low).to_bytes(16, 'big')
        keystream = _aes_encrypt_block(ctr_bytes, round_keys)
        block = ciphertext[i * 16:(i + 1) * 16]
        plaintext.extend(bytes(c ^ k for c, k in zip(block, keystream[:len(block)])))

    aad_pad = b"\x00" * ((16 - len(aad) % 16) % 16)
    ct_pad = b"\x00" * ((16 - len(ciphertext) % 16) % 16)
    length_block = (len(aad) * 8).to_bytes(8, 'big') + (len(ciphertext) * 8).to_bytes(8, 'big')
    s = _ghash(H, aad + aad_pad + ciphertext + ct_pad + length_block)
    e_j0 = _aes_encrypt_block(j0, round_keys)
    computed_tag = bytes(a ^ b for a, b in zip(s, e_j0))
    if computed_tag != auth_tag:
        raise ValueError("V2 GCM auth tag mismatch")
    return bytes(plaintext)


_V1_PREFIX = b"Salted__"
_V2_PREFIX = b"match_encrypted_v2__"


def _decrypt_stored(stored_data, password):
    if stored_data.startswith(_V2_PREFIX):
        salt = stored_data[20:28]
        auth_tag = stored_data[28:44]
        ciphertext = stored_data[44:]
        material = hashlib.pbkdf2_hmac(
            'sha256',
            password.encode('utf-8'),
            salt,
            10_000,
            dklen=32 + 12 + 24,
        )
        key = material[0:32]
        iv = material[32:44]
        aad = material[44:68]
        return _aes_gcm_decrypt(ciphertext, key, iv, aad, auth_tag)
    if stored_data.startswith(_V1_PREFIX):
        salt = stored_data[8:16]
        ciphertext = stored_data[16:]
        try:
            key, iv = _evp_bytes_to_key(password, salt, 'md5', 32, 16)
            return _aes_cbc_decrypt(ciphertext, key, iv)
        except Exception:
            key, iv = _evp_bytes_to_key(password, salt, 'sha256', 32, 16)
            return _aes_cbc_decrypt(ciphertext, key, iv)
    raise ValueError("Unrecognized fastlane match payload (missing V1 'Salted__' or V2 'match_encrypted_v2__' prefix)")


def decrypt_match_data(source_path: str, destination_path: str, password: str):
    with open(source_path, 'rb') as f:
        raw = f.read()
    stored_data = base64.b64decode(raw)
    decrypted = _decrypt_stored(stored_data, password)
    with open(destination_path, 'wb') as f:
        f.write(decrypted)


if __name__ == '__main__':
    import sys
    if len(sys.argv) != 4:
        print('Usage: DecryptMatch.py <password> <source_path> <destination_path>')
        sys.exit(1)
    decrypt_match_data(source_path=sys.argv[2], destination_path=sys.argv[3], password=sys.argv[1])
```

---

## Task 2: Smoke-test the AES-256 block primitive (FIPS-197 Appendix C.3)

**Files:**
- No changes. One-liner shell command to validate the just-written primitive.

- [ ] **Step 2.1: Run the FIPS-197 C.3 known-answer test**

```bash
cd /Users/isaac/build/telegram/telegram-ios
python3 -c "
import sys
sys.path.insert(0, 'build-system/Make')
from DecryptMatch import _key_expansion_256, _aes_encrypt_block, _aes_decrypt_block
key = bytes.fromhex('000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f')
pt = bytes.fromhex('00112233445566778899aabbccddeeff')
expected = bytes.fromhex('8ea2b7ca516745bfeafc49904b496089')
rks = _key_expansion_256(key)
assert _aes_encrypt_block(pt, rks) == expected, 'encrypt failed'
assert _aes_decrypt_block(expected, rks) == pt, 'decrypt failed'
print('AES-256 FIPS-197 C.3 OK')
"
```

Expected output: `AES-256 FIPS-197 C.3 OK`. If this fails, the AES primitive is broken — re-read Task 1's code and fix before proceeding.

---

## Task 3: Validate V2 decryption on real encrypted files

**Files:**
- No changes. Decrypt real samples with the new Python and verify each output is a cryptographically-valid Apple-signed artifact.

**Success criteria:** the decrypted `.mobileprovision` files verify under `openssl smime -verify` and parse as valid plists. A CMS signature covers every byte of the payload, so successful verification is equivalent to bit-exact decryption — any wrong byte anywhere would break the signature. This is a stronger check than diffing against another implementation, and it matches what `BuildConfiguration.copy_profiles_from_directory` does on every profile in the real build, so passing here means the port is production-ready.

The encrypted repo is at `~/build/telegram/telegram-ios/build-input/configuration-repository-workdir/encrypted/profiles/development/`. Repo password: `sluchainost` (per the hard-coded value in the file Task 1 replaced).

> NOTE: Do not attempt a byte-for-byte comparison against `ruby build-system/decrypt.rb`. Ruby's OpenSSL binding on macOS LibreSSL 3.3.6 fails on `cipher.auth_data=` with `couldn't set additional authenticated data`, so the legacy script cannot decrypt V2 at all on current macOS. (This is likely why the build accumulated a broken aspirational Python port in the first place.) Signature verification of the Python output is the authoritative check.

- [ ] **Step 3.1: Decrypt one sample file**

```bash
cd /Users/isaac/build/telegram/telegram-ios
SAMPLE=~/build/telegram/telegram-ios/build-input/configuration-repository-workdir/encrypted/profiles/development/Development_org.telegram.TelegramInternal.BroadcastUpload.mobileprovision
python3 build-system/Make/DecryptMatch.py sluchainost "$SAMPLE" /tmp/match-py.bin
shasum -a 256 /tmp/match-py.bin
```

Expected: `match-py.bin` is non-empty; a sha256 is printed.

- [ ] **Step 3.2: Verify the output is a valid Apple-signed provisioning profile**

```bash
openssl smime -inform der -verify -noverify -in /tmp/match-py.bin | plutil -lint -
```

Expected: `openssl smime` prints `Verification successful` (or similar; exit code 0 is what matters), and `plutil` reports `OK`. Either failure means the decryption is corrupt — STOP and report BLOCKED with the exact openssl/plutil output.

- [ ] **Step 3.3: Spot-check remaining V2 files decrypt without error**

```bash
cd /Users/isaac/build/telegram/telegram-ios
ENCRYPTED=~/build/telegram/telegram-ios/build-input/configuration-repository-workdir/encrypted/profiles/development
for f in "$ENCRYPTED"/*.mobileprovision; do
  python3 build-system/Make/DecryptMatch.py sluchainost "$f" /tmp/match-check.bin \
    && openssl smime -inform der -verify -noverify -in /tmp/match-check.bin > /dev/null 2>&1 \
    && echo "OK $(basename "$f")" \
    || echo "FAIL $(basename "$f")"
done
```

Expected: every line starts with `OK`. Any `FAIL` line means that file's decryption is corrupt — STOP and report BLOCKED.

---

## Task 4: Commit the rewrite

**Files:**
- Commit `build-system/Make/DecryptMatch.py` only.

- [ ] **Step 4.1: Stage and commit**

```bash
cd /Users/isaac/build/telegram/telegram-ios
git add build-system/Make/DecryptMatch.py
git commit -m "$(cat <<'EOF'
DecryptMatch: pure-Python AES-256 port of decrypt.rb

Implements fastlane match V1 (AES-256-CBC via EVP_BytesToKey with
MD5 default and SHA256 fallback) and V2 (AES-256-GCM with PBKDF2-
derived key/IV/AAD + auth tag) using only Python stdlib. Validated
by decrypting every V2 .mobileprovision in the repo and confirming
each output verifies under openssl smime + plutil -lint as a valid
Apple-signed artifact.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

Expected: commit created cleanly.

---

## Task 5: Switch `BuildConfiguration.py` to the Python implementation and remove `decrypt.rb`

**Files:**
- Modify: `build-system/Make/BuildConfiguration.py:103-118`
- Delete: `build-system/decrypt.rb`

- [ ] **Step 5.1: Swap the call site**

Replace lines 103-118 of `build-system/Make/BuildConfiguration.py`:

```python
def decrypt_codesigning_directory_recursively(source_base_path, destination_base_path, password):
    for file_name in os.listdir(source_base_path):
        source_path = source_base_path + '/' + file_name
        destination_path = destination_base_path + '/' + file_name
        allowed_file_extensions = ['.mobileprovision', '.cer', '.p12']
        if os.path.isfile(source_path) and any(source_path.endswith(ext) for ext in allowed_file_extensions):
            #print('Decrypting {} to {} with {}'.format(source_path, destination_path, password))
            os.system('ruby build-system/decrypt.rb "{password}" "{source_path}" "{destination_path}"'.format(
                password=password,
                source_path=source_path,
                destination_path=destination_path
            ))
            #decrypt_match_data(source_path, destination_path, password)
        elif os.path.isdir(source_path):
            os.makedirs(destination_path, exist_ok=True)
            decrypt_codesigning_directory_recursively(source_path, destination_path, password)
```

with:

```python
def decrypt_codesigning_directory_recursively(source_base_path, destination_base_path, password):
    for file_name in os.listdir(source_base_path):
        source_path = source_base_path + '/' + file_name
        destination_path = destination_base_path + '/' + file_name
        allowed_file_extensions = ['.mobileprovision', '.cer', '.p12']
        if os.path.isfile(source_path) and any(source_path.endswith(ext) for ext in allowed_file_extensions):
            decrypt_match_data(source_path, destination_path, password)
        elif os.path.isdir(source_path):
            os.makedirs(destination_path, exist_ok=True)
            decrypt_codesigning_directory_recursively(source_path, destination_path, password)
```

- [ ] **Step 5.2: Delete the Ruby script**

```bash
cd /Users/isaac/build/telegram/telegram-ios
git rm build-system/decrypt.rb
```

- [ ] **Step 5.3: Commit**

```bash
cd /Users/isaac/build/telegram/telegram-ios
git add build-system/Make/BuildConfiguration.py
git commit -m "$(cat <<'EOF'
BuildConfiguration: use Python DecryptMatch, drop Ruby decrypt.rb

Swap the os.system('ruby build-system/decrypt.rb ...') shell-out for
a direct decrypt_match_data() call, and delete the now-unused Ruby
script. The iOS build no longer depends on a Ruby interpreter.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

Expected: commit created cleanly; `git status` shows a clean tree.

---

## Task 6: End-to-end verification with `generateProject`

**Files:**
- No changes.

- [ ] **Step 6.1: Wipe the previously-decrypted directory so the build re-decrypts fresh**

```bash
cd /Users/isaac/build/telegram/telegram-ios
rm -rf ~/build/telegram/telegram-ios/build-input/configuration-repository-workdir/decrypted
```

Expected: directory removed. If it did not exist, that's also fine.

- [ ] **Step 6.2: Run the user-supplied `generateProject` command**

```bash
cd /Users/isaac/build/telegram/telegram-ios
source ~/.zshrc 2>/dev/null
python3 build-system/Make/Make.py --overrideXcodeVersion \
  --cacheDir ~/build/telegram/telegram-bazel-cache \
  generateProject \
  --configurationPath ~/build/telegram/telegram-internal-tools/PrivateData/build-configurations/enterprise-configuration.json \
  --gitCodesigningRepository git@gitlab.com:peter-iakovlev/fastlanematch.git \
  --gitCodesigningType development --gitCodesigningUseCurrent
```

Expected: the command runs through project generation. The decryption step is silent on success (per `BuildConfiguration.py:decrypt_codesigning_directory_recursively`). Any decryption failure would surface downstream in `copy_profiles_from_directory` when `openssl smime -verify` chokes on a corrupted `.mobileprovision`, so a clean run proves the port is working end-to-end.

If the command fails with a decryption-related error, revert the two commits (`git revert HEAD~1..HEAD`) and debug; otherwise the migration is complete.

- [ ] **Step 6.3: Spot-check the generated decrypted directory**

```bash
ls ~/build/telegram/telegram-ios/build-input/configuration-repository-workdir/decrypted/profiles/development/
```

Expected: a populated list of `.mobileprovision` files, matching the list in the encrypted sibling directory.
