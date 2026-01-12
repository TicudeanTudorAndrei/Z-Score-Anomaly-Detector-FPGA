import tkinter as tk
from tkinter import scrolledtext
import serial
import struct
import threading
import time
import numpy as np
import matplotlib
matplotlib.use('TkAgg')
import matplotlib.pyplot as plt

# === SERIAL CONFIG ===
ser = None
stop_event = threading.Event()

# === ANOMALY DETECTION CONFIG ===
threshold = 3
received_data = []
anomalies = []
nr_streams = 2
sample_size = 64

# === FIGURE ===
plt.ion()
fig, ax = plt.subplots(figsize=(12, 6))
line, = ax.plot([], [], label='Received')
scatter = ax.scatter([], [], color='red', marker='x', label='Anomaly')
ax.set_xlim(0, 300)
ax.set_ylim(-4, 4)
ax.set_title("Anomaly detection with Z-Score")
ax.set_xlabel("Index")
ax.set_ylabel("Z-Score")
ax.legend()

def display_message(message):
    output_textbox.config(state=tk.NORMAL)
    output_textbox.insert(tk.END, message + "\n")
    output_textbox.yview(tk.END)
    output_textbox.config(state=tk.DISABLED)

def send_data(number, identifier, flags=0):
    try:
        packed_number = struct.pack('>f', number)
        packed_id = struct.pack('>H', identifier)
        packed_flags = struct.pack('>H', flags)
        full_message = packed_number + packed_id + packed_flags

        display_message(f"Sending: {number} | ID: {identifier} | Flags: {flags}")

        ser.write(full_message)
        root.update()
    except Exception as e:
        display_message(f"Error sending data: {e}")

# === RECEIVE THREAD ===
def receive_data():
    idx = 0
    while not stop_event.is_set():
        if ser and ser.in_waiting >= 8:
            try:
                received_bytes = ser.read(8)
                number = struct.unpack('>f', received_bytes[:4])[0]
                identifier = struct.unpack('>H', received_bytes[4:6])[0]
                flags = struct.unpack('>H', received_bytes[6:])[0]

                # Update data in this thread
                received_data.append(number)
                if abs(number) > threshold or (flags & 0b1):
                    anomalies.append((idx, number))

                current_idx = idx  # capture for closure
                current_number = number
                current_identifier = identifier
                current_flags = flags

                idx += 1

                # UI update callback only for drawing & display
                def handle_data():
                    display_message(f"Received: {current_number} | ID: {current_identifier} | Flags: {current_flags}")
                    # display_message(f"Hex {''.join(f'{byte:02X}' for byte in received_bytes[:4])}\n")

                    # Update plot
                    line.set_data(range(len(received_data)), received_data)
                    if anomalies:
                        ax_x, ax_y = zip(*anomalies)
                        scatter.set_offsets(np.c_[ax_x, ax_y])

                    ax.set_xlim(0, max(50, len(received_data)))
                    ax.set_ylim(min(received_data) - 5, max(received_data) + 5)
                    fig.canvas.draw_idle()
                    plt.pause(0.001)

                root.after(0, handle_data)

            except Exception as e:
                display_message(f"Error receiving: {e}")

        time.sleep(0.05)



# === TKINTER ===
def on_send():
    try:
        number = float(input_entry.get())
        identifier = int(id_entry.get())
        if not (0 <= identifier <= 65535):
            raise ValueError("ID must be between 0 and 65535.")
        send_data(number, identifier)
    except ValueError as e:
        display_message(f"Invalid input: {e}")
    input_entry.delete(0, tk.END)
    id_entry.delete(0, tk.END)

def send_custom_sequence():
    sequence = [1.5] * 20 + [1.3] * 20 + [1.7] * 20 + [1.1] * 4 + [1] * 10 + [1.2] * 10 + [1.4] * 10 + [1.3] * 10 + [1.6] * 10 + [1.8] * 10 + [1.1] * 4
    alternating_ids = 0

    for i, number in enumerate(sequence):
        for repeat in range(nr_streams):
            identifier = alternating_ids % nr_streams
            alternating_ids = alternating_ids + 1
            send_data(number, identifier)
            time.sleep(0.5)

def send_synthetic_signals():
    np.random.seed(42)
    n = 300  # total samples per stream
    normal_low, normal_high = 2.0, 10.0

    # Base signal shared by all streams
    base_signal = np.random.uniform(low=normal_low, high=normal_high, size=n)

    # Add consistent anomalies every 10 samples
    anomaly_indices = np.arange(0, n, 10)
    for idx in anomaly_indices:
        if np.random.rand() > 0.5:
            base_signal[idx] += np.random.uniform(100, 200)
        else:
            base_signal[idx] -= np.random.uniform(100, 200)


    for i in range(n):
        for stream_id in range(nr_streams):
            send_data(base_signal[i], stream_id)
            time.sleep(0.5)

def on_quit():
    stop_event.set()
    if ser:
        ser.close()
    root.quit()

def start_communication():
    global ser
    try:
        ser = serial.Serial(com_entry.get(), int(baud_entry.get()), timeout=1)
        threading.Thread(target=receive_data, daemon=True).start()
        display_message(f"Started serial on {com_entry.get()} with baud rate {baud_entry.get()}\n")
        start_button.config(state=tk.DISABLED)
        stop_button.config(state=tk.NORMAL)
        send_button.config(state=tk.NORMAL)
        sequence_button.config(state=tk.NORMAL)
        synthetic_button.config(state=tk.NORMAL)
    except Exception as e:
        display_message(f"Error: {e}")
        stop_communication()

def stop_communication():
    global ser
    if ser:
        ser.close()
        ser = None
        display_message("Stopped serial.")
        start_button.config(state=tk.NORMAL)
        stop_button.config(state=tk.DISABLED)
        send_button.config(state=tk.DISABLED)
        sequence_button.config(state=tk.DISABLED)
        synthetic_button.config(state=tk.DISABLED)

root = tk.Tk()
root.title("UART + Plot Multistream")

com_frame = tk.Frame(root)
com_frame.pack(pady=5)

tk.Label(com_frame, text="COM:").pack(side=tk.LEFT)
com_entry = tk.Entry(com_frame, width=10)
com_entry.insert(0, "COM8")
com_entry.pack(side=tk.LEFT, padx=5)

tk.Label(com_frame, text="Baud:").pack(side=tk.LEFT)
baud_entry = tk.Entry(com_frame, width=10)
baud_entry.insert(0, "115200")
baud_entry.pack(side=tk.LEFT, padx=5)

start_button = tk.Button(com_frame, text="Start", command=start_communication)
start_button.pack(side=tk.LEFT, padx=5)

stop_button = tk.Button(com_frame, text="Stop", command=stop_communication, state=tk.DISABLED)
stop_button.pack(side=tk.LEFT, padx=5)

input_frame = tk.Frame(root)
input_frame.pack(pady=5)

tk.Label(input_frame, text="Float:").pack(side=tk.LEFT)
input_entry = tk.Entry(input_frame, width=10)
input_entry.pack(side=tk.LEFT, padx=5)

tk.Label(input_frame, text="ID:").pack(side=tk.LEFT)
id_entry = tk.Entry(input_frame, width=10)
id_entry.pack(side=tk.LEFT, padx=5)

send_button = tk.Button(input_frame, text="Send", command=on_send, state=tk.DISABLED)
send_button.pack(side=tk.LEFT, padx=5)

sequence_button = tk.Button(input_frame, text="Send Init Seq", command=send_custom_sequence, state=tk.DISABLED)
sequence_button.pack(side=tk.LEFT, padx=5)

synthetic_button = tk.Button(input_frame, text="Send Rand Seq", command=send_synthetic_signals, state=tk.DISABLED)
synthetic_button.pack(side=tk.LEFT, padx=5)

output_textbox = scrolledtext.ScrolledText(root, width=100, height=20, wrap=tk.NONE, state=tk.DISABLED)
output_textbox.pack(pady=5)

quit_button = tk.Button(root, text="Quit", command=on_quit)
quit_button.pack(side=tk.RIGHT, padx=5, pady=5)

root.mainloop()

if ser:
    stop_event.set()
    ser.close()