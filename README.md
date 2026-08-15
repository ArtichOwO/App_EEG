## App_EEG: User Manual

**App_EEG** is a MATLAB-based graphical interface designed to help you visualize, process, and analyze Electroencephalography (EEG) data. This guide covers how to load your data, configure your analysis parameters, and utilize the various visualization tools available in the application.

---

### 1. Getting Started: Data Loading & Configuration

Before running any analysis, you must load your data and define the specific parameters for your session.

* **Load Data:** Click the designated button in the interface to load your EEG data. The application strictly requires data to be in the **EDF (European Data Format)**. 
* **Select Signal(s):** Choose the specific EEG channel(s) you wish to analyze from the provided list. Some tools (like the Topographic Maps) automatically extract data from all 19 standard 10-20 system electrodes.
* **Set Time Offset:** Define the starting point of your analysis (in seconds) by adjusting the **Time Offset** value.
* **Set Time Window:** Define the duration of the segment you want to analyze (in seconds) using the **Time Window** control.

---

### 2. Signal Visualization Tools

These modules allow you to inspect the time-domain and frequency-domain characteristics of your selected signals.

* **Graph:** Plots the raw amplitude of one or multiple selected EEG signals over time. When multiple channels are selected, the application automatically stacks them with vertical offsets for clear comparison.
* **STFT (Short-Time Fourier Transform):** Generates a spectrogram for a single selected signal, showing how frequency content (in Hz) changes over time. It utilizes a 256-point Hamming window.
* **CWT (Continuous Wavelet Transform):** Produces a high-resolution scalogram using continuous wavelets, ideal for spotting transient and non-stationary features in your signal.
* **DWT (Discrete Wavelet Transform):** Decomposes the signal into 7 distinct levels and reconstructs them into the five classical EEG frequency bands: Gamma, Beta, Alpha, Theta, and Delta.

---

### 3. Complexity Analysis

* **ApEn (Approximate Entropy):** Measures the unpredictability and complexity of a single selected signal over time. The application uses a sliding window approach (2-second window, 1-second step size) to plot how the entropy fluctuates throughout your selected time frame.

---

### 4. Topographic Brain Mapping

Topographic maps generate 2D spatial heatmaps over a schematic head model, utilizing the standard 19-channel 10-20 electrode system. These maps interpolate data between electrodes to provide a smooth, color-coded surface.

| Mapping Tool | Description |
| :--- | :--- |
| **Brain Map — Amplitude** | Calculates the raw signal power/amplitude for the selected time window and maps its spatial distribution across the scalp. |
| **Brain Map — Frequency** | Computes the bandpower of the time segment for all 19 channels, illustrating where specific frequency activity is concentrated. |
| **Entropy Map (AppEn)** | Calculates the Approximate Entropy for all channels, providing a spatial visualization of brain state complexity and signal unpredictability. |

---

### 5. Troubleshooting & Common Errors

* **"Load an EDF file first"**: You are attempting to run an analysis or generate a map before successfully loading an EDF file into the workspace.
* **"Invalid time interval"**: The combination of your Time Offset and Time Window results in a start time that is equal to or greater than the end time. Adjust your GUI parameters to ensure a valid time frame.
* **"Selected signal is too short"**: You are trying to run the Approximate Entropy (ApEn) analysis on a segment that is shorter than the required 2-second sliding window. Increase your Time Window.

