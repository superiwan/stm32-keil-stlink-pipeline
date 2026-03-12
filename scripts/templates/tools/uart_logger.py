import argparse
import datetime as dt
import pathlib
import sys
import time

try:
    import serial
    from serial.tools import list_ports
except Exception as exc:
    print(f"[uart] import pyserial failed: {exc}")
    print("[uart] install with: pip install pyserial")
    sys.exit(2)


AUTO_KEYWORDS = ("stlink","daplink","cmsis-dap","mbed serial","usb serial","ch340","ch34","cp210","silicon labs","ftdi","pl2303")


def now_text(with_ts: bool) -> str:
    if not with_ts:
        return ""
    return dt.datetime.now().strftime("[%Y-%m-%d %H:%M:%S.%f]")[:-3] + " "


def pick_auto_port() -> str | None:
    ports = list(list_ports.comports())
    if not ports:
        return None

    scored: list[tuple[int, str]] = []
    for p in ports:
        text = f"{p.device} {p.description} {p.hwid}".lower()
        score = sum(1 for k in AUTO_KEYWORDS if k in text)
        scored.append((score, p.device))

    scored.sort(key=lambda x: x[0], reverse=True)
    if scored[0][0] <= 0:
        return None
    return scored[0][1]


def print_ports() -> None:
    ports = list(list_ports.comports())
    if not ports:
        print("[uart] no serial ports found")
        return
    print("[uart] available serial ports:")
    for p in ports:
        print(f"  - {p.device}: {p.description}")


def main() -> int:
    parser = argparse.ArgumentParser(description="Simple UART logger with auto reconnect")
    parser.add_argument("--port", required=True, help="COM port, or 'auto' for auto-detect")
    parser.add_argument("--baud", type=int, default=115200)
    parser.add_argument("--log", default="uart.log")
    parser.add_argument("--no-ts", action="store_true")
    parser.add_argument("--hex", action="store_true", help="print bytes in hex")
    parser.add_argument("--reconnect-sec", type=float, default=1.0)
    args = parser.parse_args()

    log_path = pathlib.Path(args.log)
    log_path.parent.mkdir(parents=True, exist_ok=True)

    with_ts = not args.no_ts

    while True:
        try:
            port = args.port
            if port.lower() == "auto":
                port = pick_auto_port()
                if not port:
                    print("[uart] auto port detection failed (no ST-Link/CMSIS-DAP-like serial port found)")
                    print_ports()
                    time.sleep(args.reconnect_sec)
                    continue

            print(f"[uart] opening {port} @ {args.baud}")
            with serial.Serial(port, args.baud, timeout=0.2) as ser, log_path.open("a", encoding="utf-8") as f:
                print("[uart] connected. Ctrl+C to stop.")
                while True:
                    data = ser.read(512)
                    if not data:
                        continue

                    if args.hex:
                        payload = data.hex(" ") + "\n"
                    else:
                        payload = data.decode("utf-8", errors="replace")

                    line = now_text(with_ts) + payload
                    sys.stdout.write(line)
                    sys.stdout.flush()
                    f.write(line)
                    f.flush()
        except KeyboardInterrupt:
            print("\n[uart] stopped by user")
            return 0
        except Exception as exc:
            print(f"[uart] disconnected/error: {exc}")
            time.sleep(args.reconnect_sec)


if __name__ == "__main__":
    raise SystemExit(main())

