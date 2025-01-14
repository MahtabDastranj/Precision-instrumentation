% Load EEG data
load(%Your Data Path%);
eeg_signal = Data; % Assign the EEG signal
Fs = 173.61; % Sampling frequency in Hz

% ---------------------------
% Step 1: Original Signal Analysis
% ---------------------------
% Plot original signal
figure;
tiledlayout(2, 1); % Use a tiled layout for compact visualization

nexttile;
plot(eeg_signal, 'LineWidth', 1);
title('Original EEG Signal');
xlabel('Sample Index');
ylabel('Amplitude');
grid on;

% Power Spectral Density (PSD) of original signal
[pxx_original, f_original] = periodogram(eeg_signal, [], [], Fs);

nexttile;
plot(f_original, 10*log10(pxx_original), 'LineWidth', 1);
title('Power Spectral Density of Original Signal');
xlabel('Frequency (Hz)');
ylabel('Power/Frequency (dB/Hz)');
grid on;

% ---------------------------
% Step 2: Signal Conditioning
% ---------------------------
% Amplify and attenuate signals
factors = [2, 0.5]; % Amplify by 2, attenuate by 0.5
eeg_amplified = eeg_signal * factors(1);
eeg_attenuated = eeg_signal * factors(2);

% Visualize amplified and attenuated signals
figure;
tiledlayout(2, 1);

nexttile;
plot(eeg_amplified, 'LineWidth', 1);
title('Amplified Signal (x2)');
xlabel('Sample Index');
ylabel('Amplitude');
grid on;

nexttile;
plot(eeg_attenuated, 'LineWidth', 1);
title('Attenuated Signal (x0.5)');
xlabel('Sample Index');
ylabel('Amplitude');
grid on;

% Rectify signals: Half-wave and full-wave
eeg_half_rectified = max(eeg_signal, 0); % Half-wave
eeg_full_rectified = abs(eeg_signal);   % Full-wave

% Plot rectified signals
figure;
tiledlayout(2, 1);

nexttile;
plot(eeg_half_rectified, 'LineWidth', 1);
title('Half-Wave Rectified Signal');
xlabel('Sample Index');
ylabel('Amplitude');
grid on;

nexttile;
plot(eeg_full_rectified, 'LineWidth', 1);
title('Full-Wave Rectified Signal');
xlabel('Sample Index');
ylabel('Amplitude');
grid on;

% ---------------------------
% Step 3: Filtering
% ---------------------------
% Design filters
bpFilt = designfilt('bandpassiir', ...
    'FilterOrder', 4, ...
    'HalfPowerFrequency1', 0.5, ...
    'HalfPowerFrequency2', 80, ...
    'SampleRate', Fs); % Bandpass
notchFilt = designfilt('bandstopiir', ...
    'FilterOrder', 2, ...
    'HalfPowerFrequency1', 49, ...
    'HalfPowerFrequency2', 51, ...
    'SampleRate', Fs); % Notch

% Apply filters
eeg_filtered = filtfilt(notchFilt, filtfilt(bpFilt, eeg_signal));

% Compare original and filtered signals
figure;
stackedplot(table(eeg_signal, eeg_filtered), 'Title', 'EEG Signal: Original vs. Filtered', ...
    'DisplayLabels', {'Original Signal', 'Filtered Signal'});

% PSD of filtered signal
[pxx_filtered, f_filtered] = periodogram(eeg_filtered, [], [], Fs);

figure;
plot(f_original, 10*log10(pxx_original), 'LineWidth', 1);
hold on;
plot(f_filtered, 10*log10(pxx_filtered), 'LineWidth', 1);
title('Power Spectral Density: Original vs. Filtered Signal');
xlabel('Frequency (Hz)');
ylabel('Power/Frequency (dB/Hz)');
legend('Original Signal', 'Filtered Signal');
grid on;

% ---------------------------
% Step 4: Frequency Band Analysis
% ---------------------------
% Define EEG frequency bands
bands = struct('Delta', [0.5, 4], 'Theta', [4, 8], 'Alpha', [8, 13], ...
               'Beta', [13, 30], 'Gamma', [30, 80]);

% Initialize power containers
original_band_power = [];
filtered_band_power = [];

% Calculate band power for original and filtered signals
figure;
tiledlayout(5, 1);

band_names = fieldnames(bands);
for i = 1:length(band_names)
    % Get band range
    band = bands.(band_names{i});
    
    % Bandpass filter for current band
    bandFilt = designfilt('bandpassiir', ...
        'FilterOrder', 4, ...
        'HalfPowerFrequency1', band(1), ...
        'HalfPowerFrequency2', band(2), ...
        'SampleRate', Fs);
    
    % Filter signals
    original_band = filtfilt(bandFilt, eeg_signal);
    filtered_band = filtfilt(bandFilt, eeg_filtered);
    
    % Calculate power
    original_band_power(i) = bandpower(original_band, Fs, band);
    filtered_band_power(i) = bandpower(filtered_band, Fs, band);
    
    % Plot band signals
    nexttile;
    plot(original_band, 'LineWidth', 1);
    hold on;
    plot(filtered_band, 'LineWidth', 1);
    title([band_names{i}, ' Band']);
    legend('Original', 'Filtered');
    xlabel('Sample Index');
    ylabel('Amplitude');
    grid on;
end

% ---------------------------
% Step 5: Display Results in a Table
% ---------------------------
% Create a table of power comparisons
power_table = table(band_names, original_band_power', filtered_band_power', ...
    'VariableNames', {'Band', 'Original_Power', 'Filtered_Power'});

% Display the table
disp('Power Comparison Between Bands:');
disp(power_table);

% ---------------------------
% Step 6: Metric Calculations
% ---------------------------
% SNR Calculation
SNR = snr(eeg_filtered, eeg_signal - eeg_filtered);

% Total Harmonic Distortion (THD)
THD = thd(eeg_filtered, Fs);

% Display results
disp(['Signal-to-Noise Ratio (SNR): ', num2str(SNR), ' dB']);
disp(['Total Harmonic Distortion (THD): ', num2str(THD), ' %']);
