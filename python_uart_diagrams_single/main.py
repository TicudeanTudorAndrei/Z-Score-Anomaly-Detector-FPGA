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
import random

ser = None
stop_event = threading.Event()

threshold = 3
rec_data = []
anomalies = []
ground_truth = []  # 1 = anomaly , 0 = normal
predicted = []     # 1 = anomaly, 0 = normal

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

def send_float(number):
    try:
        packed_num = struct.pack('>f', number)
        display_message(f"Sending: {number}")
        display_message(f"Binary: {''.join(f'{byte:08b}' for byte in packed_num)}")
        display_message(f"Hex: {''.join(f'{byte:02X}' for byte in packed_num)}\n")

        ser.write(packed_num)
        root.update()
    except Exception as e:
        display_message(f"Send error: {e}\n")

def receive_float():
    global idx
    idx = len(rec_data)

    if ser and ser.in_waiting >= 4:
        try:
            rec_bytes = ser.read(4)
            number = struct.unpack('>f', rec_bytes)[0]
            rec_data.append(number)

            if abs(number) > threshold:
                anomalies.append((idx, number))
                predicted.append(1)
            else:
                predicted.append(0)

            display_message(f"Received: {number}")
            display_message(f"Binary: {''.join(f'{byte:08b}' for byte in rec_bytes)}")
            display_message(f"Hex: {''.join(f'{byte:02X}' for byte in rec_bytes)}\n")

            line.set_data(range(len(rec_data)), rec_data)

            if anomalies:
                ax_x, ax_y = zip(*anomalies)
                scatter.set_offsets(np.c_[ax_x, ax_y])

            ax.set_xlim(0, max(50, len(rec_data)))
            ax.set_ylim(min(rec_data) - 5, max(rec_data) + 5)
            fig.canvas.draw_idle()

        except Exception as e:
            display_message(f"Receive error: {e}")

    root.after(50, receive_float)

def on_send():
    try:
        number = float(input_entry.get())
        send_float(number)
    except ValueError:
        display_message("Invalid input. Enter a float.\n")
    input_entry.delete(0, tk.END)

def send_predef_sequence():
    sequence = [1.5] * 20 + [1.3] * 20 + [1.7] * 20 + [1.1] * 4 + [1] * 10 + [1.2] * 10 + [1.4] * 10 + [1.3] * 10 + [1.6] * 10 + [1.8] * 10 + [1.1] * 4
    for number in sequence:
        send_float(number)
        time.sleep(0.5)

def send_rand_sequence():
    for i in range(300):
        number = random.gauss(1.5, 1)
        is_anomaly = 0

        if random.random() < 0.05: # 5%
            spike = random.uniform(50, 100)
            if random.choice([True, False]):
                number += spike
            else:
                number -= spike
            is_anomaly = 1

        ground_truth.append(is_anomaly)
        send_float(number)
        time.sleep(0.5)
    if ground_truth and predicted:
        compute_metrics()

def compute_metrics():
    TP = FP = TN = FN = 0
    for gt, pred in zip(ground_truth, predicted):
        if gt == 1 and pred == 1:
            TP += 1
        elif gt == 0 and pred == 1:
            FP += 1
        elif gt == 1 and pred == 0:
            FN += 1
        elif gt == 0 and pred == 0:
            TN += 1

    precision = TP / (TP + FP) if (TP + FP) > 0 else 0
    recall = TP / (TP + FN) if (TP + FN) > 0 else 0
    accuracy = (TP + TN) / (TP + TN + FP + FN) if (TP + TN + FP + FN) > 0 else 0
    f1 = (2 * precision * recall) / (precision + recall) if (precision + recall) > 0 else 0

    display_message(f"\n------ METRICS ------")
    display_message(f"TP: {TP}, FP: {FP}, TN: {TN}, FN: {FN}")
    display_message(f"Precision: {precision:.3f}")
    display_message(f"Recall: {recall:.3f}")
    display_message(f"Accuracy: {accuracy:.3f}")
    display_message(f"F1-score: {f1:.3f}\n")

def on_quit():
    stop_event.set()
    if ser:
        ser.close()
    root.quit()

def start_communication():
    global ser
    try:
        ser = serial.Serial(com_entry.get(), int(baud_entry.get()), timeout=1)
        threading.Thread(target=receive_float, daemon=True).start()
        display_message(f"Started on {com_entry.get()} @ {baud_entry.get()}\n")
        start_button.config(state=tk.DISABLED)
        stop_button.config(state=tk.NORMAL)
        send_button.config(state=tk.NORMAL)
        sequence_button.config(state=tk.NORMAL)
        generate_button.config(state=tk.NORMAL)
    except Exception as e:
        display_message(f"Error: {e}\n")
        stop_communication()

def stop_communication():
    global ser
    if ser:
        ser.close()
        ser = None
        display_message("Stopped serial.\n")
        start_button.config(state=tk.NORMAL)
        stop_button.config(state=tk.DISABLED)
        send_button.config(state=tk.DISABLED)
        sequence_button.config(state=tk.DISABLED)
        generate_button.config(state=tk.DISABLED)

root = tk.Tk()
root.title("UART + Plot Singlestream")

com_frame = tk.Frame(root)
com_frame.pack(pady=5)

tk.Label(com_frame, text="COM Port:").pack(side=tk.LEFT)
com_entry = tk.Entry(com_frame, width=10)
com_entry.pack(side=tk.LEFT, padx=5)
com_entry.insert(0, 'COM8')

tk.Label(com_frame, text="Baud Rate:").pack(side=tk.LEFT)
baud_entry = tk.Entry(com_frame, width=10)
baud_entry.pack(side=tk.LEFT, padx=5)
baud_entry.insert(0, '115200')

start_button = tk.Button(com_frame, text="Start", command=start_communication)
start_button.pack(side=tk.LEFT, padx=5)

stop_button = tk.Button(com_frame, text="Stop", command=stop_communication, state=tk.DISABLED)
stop_button.pack(side=tk.LEFT, padx=5)

input_frame = tk.Frame(root)
input_frame.pack(pady=5)

tk.Label(input_frame, text="Float:").pack(side=tk.LEFT)
input_entry = tk.Entry(input_frame, width=10)
input_entry.pack(side=tk.LEFT, padx=5)

send_button = tk.Button(input_frame, text="Send", command=on_send, state=tk.DISABLED)
send_button.pack(side=tk.LEFT, padx=5)

sequence_button = tk.Button(input_frame, text="Send Init Seq", command=send_predef_sequence, state=tk.DISABLED)
sequence_button.pack(side=tk.LEFT, padx=5)

generate_button = tk.Button(input_frame, text="Generate Rand Seq", command=send_rand_sequence, state=tk.DISABLED)
generate_button.pack(side=tk.LEFT, padx=5)

output_textbox = scrolledtext.ScrolledText(root, width=100, height=20, wrap=tk.NONE, state=tk.DISABLED)
output_textbox.pack(pady=5)

quit_button = tk.Button(root, text="Quit", command=on_quit)
quit_button.pack(side=tk.RIGHT, padx=5, pady=5)

root.mainloop()

if ser:
    stop_event.set()
    ser.close()