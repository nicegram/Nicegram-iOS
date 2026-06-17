#!/usr/bin/env python3
"""
Synthetic simulator for TextRevealController.

Mirrors the algorithm in
submodules/TelegramUI/Components/Chat/ChatMessageTextBubbleContentNode/
Sources/ChatMessageTextBubbleContentNode.swift verbatim (`TextRevealController`).

Iterate here before changing the Swift code. To port a change back, update
TextRevealController in the .swift file with the same edits.

Usage:
    python3 docs/superpowers/scratch/reveal-pacing-sim.py [scenario]
        scenario = bursty | speed-change | big-chunk | finalize-backlog |
                   llm-stream | all (default: all)
"""

from __future__ import annotations

import sys
from dataclasses import dataclass
from typing import List, Optional, Tuple


# ---------------------------------------------------------------------------
# Controller — must stay byte-for-byte equivalent to the Swift implementation.
# ---------------------------------------------------------------------------

CONTROLLER_NAME = "v1"   # set by --algo flag in main()


class TextRevealController:
    """V1 — current Swift implementation.

    Maintains an EWMA chars/sec input rate and reveals at
        target_velocity = input_rate + max(0, lag - input_rate*headroom) / response_time
    Works for dense streams (small chunks, high arrival rate), fails for
    bursty/sparse streams (reveal burns through each chunk too quickly,
    then idles until the next chunk lands)."""

    HEADROOM_TIME = 0.4
    RESPONSE_TIME = 0.3
    VELOCITY_TAU = 0.15
    RATE_EWMA_ALPHA = 0.4
    INITIAL_INPUT_RATE = 40.0
    MIN_INTER_ARRIVAL = 0.05
    FINALIZE_TIME = 0.3
    FRAME_DT_CAP = 0.05

    def __init__(self, initial_revealed_count: int, initial_length: int) -> None:
        self.revealed_count: float = float(initial_revealed_count)
        self.velocity: float = 0.0
        self.input_rate: float = self.INITIAL_INPUT_RATE
        self.last_sample_time: Optional[float] = None
        self.last_sample_length: Optional[int] = None
        self.latest_length: int = initial_length
        self.is_finalizing: bool = False
        self.last_frame_time: Optional[float] = None

    @property
    def current_glyph_count(self) -> int:
        return int(self.revealed_count)

    def observe_update(self, latest_length: int, now: float) -> None:
        if self.last_sample_length is not None:
            last_len = self.last_sample_length
            if latest_length > last_len:
                if self.last_sample_time is not None:
                    dt = max(now - self.last_sample_time, self.MIN_INTER_ARRIVAL)
                    sample_rate = (latest_length - last_len) / dt
                    self.input_rate = (
                        self.RATE_EWMA_ALPHA * sample_rate
                        + (1.0 - self.RATE_EWMA_ALPHA) * self.input_rate
                    )
                self.last_sample_time = now
                self.last_sample_length = latest_length
            elif latest_length < last_len:
                self.last_sample_length = latest_length
        else:
            self.last_sample_time = now
            self.last_sample_length = latest_length
        self.latest_length = latest_length
        if self.revealed_count > float(latest_length):
            self.revealed_count = float(latest_length)

    def finalize(self, final_length: int) -> None:
        self.latest_length = final_length
        self.is_finalizing = True
        if self.revealed_count > float(final_length):
            self.revealed_count = float(final_length)

    def tick(self, now: float) -> Tuple[int, bool]:
        last_frame = self.last_frame_time if self.last_frame_time is not None else now
        dt = min(now - last_frame, self.FRAME_DT_CAP)
        lag = max(0.0, float(self.latest_length) - self.revealed_count)
        if self.is_finalizing:
            target_velocity = max(self.velocity, lag / self.FINALIZE_TIME)
        else:
            target_lag = self.input_rate * self.HEADROOM_TIME
            excess = max(0.0, lag - target_lag)
            target_velocity = self.input_rate + excess / self.RESPONSE_TIME
        smoothing = min(1.0, dt / self.VELOCITY_TAU)
        self.velocity += (target_velocity - self.velocity) * smoothing
        self.revealed_count = min(
            float(self.latest_length),
            self.revealed_count + self.velocity * dt,
        )
        self.last_frame_time = now
        is_complete = (
            self.is_finalizing and self.revealed_count >= float(self.latest_length)
        )
        return int(self.revealed_count), is_complete


class TextRevealControllerV2:
    """V2 — expected-next-arrival pacing.

    Tracks the EWMA of inter-arrival times between chunks. On each tick,
    aims to finish revealing the remaining lag by the predicted arrival
    time of the next chunk:
        target_velocity = lag / max(MIN_GAP, predicted_next_arrival - now)
    For steady streams (chunks every T seconds, ΔC chars each), this
    converges to lag/T ≈ continuous flow rate, with no burst-then-idle."""

    VELOCITY_TAU = 0.12          # slightly snappier than v1 since target is steadier
    GAP_EWMA_ALPHA = 0.4
    INITIAL_GAP = 0.5            # used until 2 chunks have arrived
    MIN_PREDICTED_GAP = 0.10     # floor on time-to-next (final-burst regime)
    FINALIZE_TIME = 0.3
    FRAME_DT_CAP = 0.05
    INITIAL_INPUT_RATE = 40.0    # fallback velocity for the first chunk
    # When predicted_next_arrival has passed (stream stalled), don't speed up
    # further — clamp time_to_next at this minimum.
    STALL_FLOOR = 0.10

    def __init__(self, initial_revealed_count: int, initial_length: int) -> None:
        self.revealed_count: float = float(initial_revealed_count)
        self.velocity: float = 0.0
        self.avg_inter_arrival: float = self.INITIAL_GAP
        self.last_sample_time: Optional[float] = None
        self.last_sample_length: Optional[int] = None
        self.predicted_next_arrival_time: Optional[float] = None
        self.chunk_count: int = 0
        self.latest_length: int = initial_length
        self.is_finalizing: bool = False
        self.last_frame_time: Optional[float] = None
        # Display-only: track the most-recent observed input rate for tracing.
        self.input_rate: float = self.INITIAL_INPUT_RATE

    @property
    def current_glyph_count(self) -> int:
        return int(self.revealed_count)

    def observe_update(self, latest_length: int, now: float) -> None:
        if self.last_sample_length is not None:
            last_len = self.last_sample_length
            if latest_length > last_len:
                if self.last_sample_time is not None:
                    inter_arrival = max(now - self.last_sample_time, 0.001)
                    self.avg_inter_arrival = (
                        self.GAP_EWMA_ALPHA * inter_arrival
                        + (1.0 - self.GAP_EWMA_ALPHA) * self.avg_inter_arrival
                    )
                    # Display-only rate for tracing.
                    self.input_rate = (latest_length - last_len) / inter_arrival
                self.last_sample_time = now
                self.last_sample_length = latest_length
                self.predicted_next_arrival_time = now + self.avg_inter_arrival
                self.chunk_count += 1
            elif latest_length < last_len:
                self.last_sample_length = latest_length
        else:
            self.last_sample_time = now
            self.last_sample_length = latest_length
            self.predicted_next_arrival_time = now + self.avg_inter_arrival
            self.chunk_count += 1
        self.latest_length = latest_length
        if self.revealed_count > float(latest_length):
            self.revealed_count = float(latest_length)

    def finalize(self, final_length: int) -> None:
        self.latest_length = final_length
        self.is_finalizing = True
        if self.revealed_count > float(final_length):
            self.revealed_count = float(final_length)

    def tick(self, now: float) -> Tuple[int, bool]:
        last_frame = self.last_frame_time if self.last_frame_time is not None else now
        dt = min(now - last_frame, self.FRAME_DT_CAP)
        lag = max(0.0, float(self.latest_length) - self.revealed_count)
        if self.is_finalizing:
            target_velocity = max(self.velocity, lag / self.FINALIZE_TIME)
        elif self.chunk_count < 2 or self.predicted_next_arrival_time is None:
            # Bootstrap: not enough samples to predict inter-arrival rhythm.
            # Cruise at the initial rate (matches legacy behavior for the first
            # chunk; subsequent chunks switch to predicted-arrival pacing).
            target_velocity = self.INITIAL_INPUT_RATE if lag > 0 else 0.0
        else:
            time_to_next = max(self.STALL_FLOOR, self.predicted_next_arrival_time - now)
            target_velocity = lag / time_to_next
        smoothing = min(1.0, dt / self.VELOCITY_TAU)
        self.velocity += (target_velocity - self.velocity) * smoothing
        self.revealed_count = min(
            float(self.latest_length),
            self.revealed_count + self.velocity * dt,
        )
        self.last_frame_time = now
        is_complete = (
            self.is_finalizing and self.revealed_count >= float(self.latest_length)
        )
        return int(self.revealed_count), is_complete


def make_controller(initial_revealed_count: int, initial_length: int):
    if CONTROLLER_NAME == "v2":
        return TextRevealControllerV2(initial_revealed_count, initial_length)
    return TextRevealController(initial_revealed_count, initial_length)


def compute_target_velocity_for_trace(controller, lag: float) -> float:
    """Mirror the controller's target-velocity math without mutating state."""
    if isinstance(controller, TextRevealControllerV2):
        if controller.is_finalizing:
            return max(controller.velocity, lag / controller.FINALIZE_TIME)
        if controller.predicted_next_arrival_time is None:
            return controller.INITIAL_INPUT_RATE if lag > 0 else 0.0
        # Recover "now" from last_frame_time (caller passes it).
        # We compute against last_frame_time which is updated by tick already.
        # For tracing purposes, callers should pass the same now used in tick.
        raise RuntimeError("Use compute_target_velocity_with_now for v2")
    # v1
    if controller.is_finalizing:
        return max(controller.velocity, lag / controller.FINALIZE_TIME)
    target_lag = controller.input_rate * controller.HEADROOM_TIME
    excess = max(0.0, lag - target_lag)
    return controller.input_rate + excess / controller.RESPONSE_TIME


def compute_target_velocity_with_now(controller, lag: float, now: float) -> float:
    if isinstance(controller, TextRevealControllerV2):
        if controller.is_finalizing:
            return max(controller.velocity, lag / controller.FINALIZE_TIME)
        if controller.chunk_count < 2 or controller.predicted_next_arrival_time is None:
            return controller.INITIAL_INPUT_RATE if lag > 0 else 0.0
        time_to_next = max(
            controller.STALL_FLOOR,
            controller.predicted_next_arrival_time - now,
        )
        return lag / time_to_next
    return compute_target_velocity_for_trace(controller, lag)


# ---------------------------------------------------------------------------
# Test driver
# ---------------------------------------------------------------------------

@dataclass
class Event:
    timestamp: float
    kind: str        # "chunk" or "finalize"
    length: int      # cumulative draft text length at this event


def run_scenario(
    name: str,
    events: List[Event],
    max_duration: float,
    fps: int = 60,
    trace_every_n_frames: int = 6,   # ~10 lines/sec at 60fps
) -> None:
    print(f"\n=== {name} ===")
    print(f"events: {len(events)}, fps: {fps}, max duration: {max_duration}s")
    print()

    controller = None
    frame_dt = 1.0 / fps
    t = 0.0
    event_idx = 0
    last_traced_frame = -trace_every_n_frames
    frame_count = 0
    last_int_reveal = -1

    header = f"{'t':>7s} {'reveal':>7s} {'latest':>7s} {'v':>6s} {'target':>7s} {'rate':>6s} {'lag':>6s} {'mode':>5s}"
    print(header)
    print("-" * len(header))

    while t <= max_duration:
        # Apply any events whose timestamp has elapsed.
        while event_idx < len(events) and events[event_idx].timestamp <= t + 1e-9:
            ev = events[event_idx]
            if controller is None and ev.kind == "chunk":
                controller = make_controller(
                    initial_revealed_count=0, initial_length=ev.length
                )
                print(f"[{t:6.3f}s] CREATE initial_length={ev.length} algo={CONTROLLER_NAME}")
            if controller is not None:
                if ev.kind == "chunk":
                    prev_rate = controller.input_rate
                    prev_len = controller.last_sample_length
                    controller.observe_update(ev.length, t)
                    prev_len_str = "nil" if prev_len is None else str(prev_len)
                    print(
                        f"[{t:6.3f}s] CHUNK "
                        f"len={prev_len_str}→{ev.length} "
                        f"input_rate={prev_rate:.1f}→{controller.input_rate:.1f}"
                    )
                elif ev.kind == "finalize":
                    controller.finalize(ev.length)
                    print(
                        f"[{t:6.3f}s] FINALIZE "
                        f"final_length={ev.length} "
                        f"revealed={controller.revealed_count:.1f} "
                        f"lag={controller.latest_length - controller.revealed_count:.1f}"
                    )
            event_idx += 1

        if controller is None:
            t += frame_dt
            frame_count += 1
            continue

        # Recompute the target/lag for trace output (controller.tick does it
        # internally but doesn't expose them). Mirror the math for the active algo.
        lag_for_trace = max(0.0, controller.latest_length - controller.revealed_count)
        target_v = compute_target_velocity_with_now(controller, lag_for_trace, t)

        revealed, complete = controller.tick(t)

        # Trace every N frames OR whenever the integer reveal advanced.
        should_trace = (
            (frame_count - last_traced_frame >= trace_every_n_frames)
            or (revealed != last_int_reveal)
        )
        if should_trace:
            mode = "FIN" if controller.is_finalizing else "RUN"
            print(
                f"{t:7.3f} {controller.revealed_count:7.1f} {controller.latest_length:7d} "
                f"{controller.velocity:6.1f} {target_v:7.1f} "
                f"{controller.input_rate:6.1f} {lag_for_trace:6.1f} {mode:>5s}"
            )
            last_traced_frame = frame_count
            last_int_reveal = revealed

        if complete:
            print(f"[{t:6.3f}s] COMPLETE")
            break
        t += frame_dt
        frame_count += 1

    print()


# ---------------------------------------------------------------------------
# Scenarios
# ---------------------------------------------------------------------------

def scenario_bursty() -> None:
    """LLM model emits 20 chars every 1 second for 10 chunks, then finalize.

    What we want: reveal flows continuously at ~20 chars/sec, lag stays roughly
    constant.
    What "bursty rhythm" failure looks like: reveal sprints after each chunk
    then idles (visible v drops to 0 between chunks)."""
    events: List[Event] = []
    length = 0
    for i in range(10):
        length += 20
        events.append(Event(timestamp=(i + 1) * 1.0, kind="chunk", length=length))
    events.append(Event(timestamp=11.0, kind="finalize", length=length))
    run_scenario("Bursty: 20 chars / 1s × 10", events, max_duration=12.5)


def scenario_speed_change() -> None:
    """Three slow chunks (10c every 1s) then three fast chunks (50c every 0.5s)."""
    events: List[Event] = []
    length = 0
    t = 0.0
    for _ in range(3):
        t += 1.0
        length += 10
        events.append(Event(timestamp=t, kind="chunk", length=length))
    for _ in range(3):
        t += 0.5
        length += 50
        events.append(Event(timestamp=t, kind="chunk", length=length))
    events.append(Event(timestamp=t + 1.5, kind="finalize", length=length))
    run_scenario("Speed change: slow then fast", events, max_duration=8.0)


def scenario_big_chunk() -> None:
    """One 200-char chunk all at once. Should reveal gradually, not in <0.5s."""
    events = [
        Event(timestamp=0.0, kind="chunk", length=200),
        Event(timestamp=8.0, kind="finalize", length=200),
    ]
    run_scenario("Big-chunk shock: 200 chars at once", events, max_duration=10.0)


def scenario_finalize_backlog() -> None:
    """Stream ends while reveal still far behind. Should decelerate to final ≤0.3s."""
    events = [
        Event(timestamp=0.0, kind="chunk", length=50),
        Event(timestamp=0.5, kind="chunk", length=100),
        Event(timestamp=1.0, kind="chunk", length=150),
        Event(timestamp=1.5, kind="finalize", length=200),
    ]
    run_scenario("Finalize with 200-char backlog", events, max_duration=3.5)


def scenario_llm_stream() -> None:
    """Plausible LLM streaming: ~30 chars/sec average, chunks of 3-8 chars every
    ~150ms. Some jitter."""
    import random
    random.seed(42)
    events: List[Event] = []
    length = 0
    t = 0.0
    for _ in range(60):
        dt = max(0.05, random.gauss(0.15, 0.04))
        delta = max(1, int(random.gauss(5, 1.5)))
        t += dt
        length += delta
        events.append(Event(timestamp=t, kind="chunk", length=length))
    events.append(Event(timestamp=t + 1.0, kind="finalize", length=length))
    run_scenario(
        f"LLM stream: 60 small chunks, ~30 c/s, final length {length}",
        events,
        max_duration=t + 3.0,
    )


def scenario_sparse() -> None:
    """Very sparse: 30 chars every 2 seconds. Stresses the headroom-vs-gap mismatch."""
    events: List[Event] = []
    length = 0
    for i in range(5):
        length += 30
        events.append(Event(timestamp=(i + 1) * 2.0, kind="chunk", length=length))
    events.append(Event(timestamp=12.0, kind="finalize", length=length))
    run_scenario("Sparse: 30 chars / 2s × 5", events, max_duration=13.0)


SCENARIOS = {
    "bursty": scenario_bursty,
    "speed-change": scenario_speed_change,
    "big-chunk": scenario_big_chunk,
    "finalize-backlog": scenario_finalize_backlog,
    "llm-stream": scenario_llm_stream,
    "sparse": scenario_sparse,
}


if __name__ == "__main__":
    # Args: [scenario] [--algo v1|v2]
    args = sys.argv[1:]
    if "--algo" in args:
        i = args.index("--algo")
        algo = args[i + 1]
        if algo not in ("v1", "v2"):
            print(f"Unknown algo: {algo}; must be v1 or v2")
            sys.exit(1)
        CONTROLLER_NAME = algo
        del args[i : i + 2]
    arg = args[0] if args else "all"
    if arg == "all":
        for fn in SCENARIOS.values():
            fn()
    elif arg in SCENARIOS:
        SCENARIOS[arg]()
    else:
        print(f"Unknown scenario: {arg}")
        print(f"Available: {', '.join(SCENARIOS.keys())}, all")
        sys.exit(1)
