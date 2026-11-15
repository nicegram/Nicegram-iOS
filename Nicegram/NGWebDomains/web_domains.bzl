# The single place the Nicegram web domains are written, in two families.
# NICEGRAM_ALL_DOMAINS: every Nicegram web domain the app claims; auxiliary
# entries are prefixed forms of the primary so the domain itself is never repeated.
# Nicegram Business: its own family, kept out of NICEGRAM_ALL_DOMAINS because
# WebDomains.contains would count its hosts as the Nicegram domain. Only its
# universal-link domain is claimed.
NICEGRAM_PRIMARY_DOMAIN = "nicegram.me"
NICEGRAM_ALL_DOMAINS = [
    NICEGRAM_PRIMARY_DOMAIN,
    "www." + NICEGRAM_PRIMARY_DOMAIN,
]
NICEGRAM_BUSINESS_PRIMARY_DOMAIN = "business.nicegram.ai"
NICEGRAM_BUSINESS_UNIVERSAL_LINK_DOMAIN = "link.nicegram.ai"
