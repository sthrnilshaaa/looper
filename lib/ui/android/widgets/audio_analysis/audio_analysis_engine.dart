part of 'audio_analysis_widget.dart';

class _MediaInfo {
  final int fileSize;
  final String codec;
  final String container;
  final String decodedSampleFormat;
  final int sampleRate;
  final int channels;
  final String channelLayout;
  final int bitsPerSample;
  final double duration;
  final int bitrate;
  final int totalSamples;

  const _MediaInfo({
    required this.fileSize,
    required this.codec,
    required this.container,
    required this.decodedSampleFormat,
    required this.sampleRate,
    required this.channels,
    required this.channelLayout,
    required this.bitsPerSample,
    required this.duration,
    required this.bitrate,
    required this.totalSamples,
  });
}

class _AnalysisParams {
  final Uint8List pcmBytes;
  final int sampleRate;
  final int bitsPerSample;

  const _AnalysisParams({
    required this.pcmBytes,
    required this.sampleRate,
    required this.bitsPerSample,
  });
}

class _AnalysisResult {
  final double dynamicRange;
  final double peakAmplitude;
  final double rmsLevel;
  final int totalSamples;
  final SpectrogramData? spectrum;

  const _AnalysisResult({
    required this.dynamicRange,
    required this.peakAmplitude,
    required this.rmsLevel,
    required this.totalSamples,
    this.spectrum,
  });
}

_AnalysisResult _analyzeInIsolate(_AnalysisParams params) {
  final byteData = ByteData.sublistView(params.pcmBytes);
  final sampleCount = params.pcmBytes.length ~/ 2;
  final samples = Float64List(sampleCount);

  for (int i = 0; i < sampleCount; i++) {
    final raw = byteData.getInt16(i * 2, Endian.little);
    samples[i] = raw / 32768.0;
  }

  double peak = 0;
  double sumSquares = 0;
  for (int i = 0; i < samples.length; i++) {
    final abs = samples[i].abs();
    if (abs > peak) peak = abs;
    sumSquares += samples[i] * samples[i];
  }

  final peakDB = peak > 0 ? 20.0 * math.log(peak) / math.ln10 : -100.0;
  final rms = math.sqrt(sumSquares / samples.length);
  final rmsDB = rms > 0 ? 20.0 * math.log(rms) / math.ln10 : -100.0;

  SpectrogramData? spectrum;
  if (samples.length >= 8192) {
    spectrum = _computeSpectrum(samples, params.sampleRate);
  }

  return _AnalysisResult(
    dynamicRange: peakDB - rmsDB,
    peakAmplitude: peakDB,
    rmsLevel: rmsDB,
    totalSamples: sampleCount,
    spectrum: spectrum,
  );
}

SpectrogramData _computeSpectrum(Float64List samples, int sampleRate) {
  const fftSize = 8192;
  const numSlices = 300;
  const freqBins = fftSize ~/ 2;

  final duration = samples.length / sampleRate;
  var samplesPerSlice = samples.length ~/ numSlices;
  var actualSlices = numSlices;
  if (samplesPerSlice < fftSize) {
    samplesPerSlice = fftSize;
    actualSlices = samples.length ~/ fftSize;
  }

  final magnitudes = <Float64List>[];

  for (int i = 0; i < actualSlices; i++) {
    final start = i * samplesPerSlice;
    if (start + fftSize > samples.length) break;

    final windowed = Float64List(fftSize);
    for (int j = 0; j < fftSize; j++) {
      final w = 0.5 * (1.0 - math.cos(2.0 * math.pi * j / (fftSize - 1)));
      windowed[j] = samples[start + j] * w;
    }

    final spectrum = _fft(windowed);

    final mags = Float64List(freqBins);
    for (int j = 0; j < freqBins; j++) {
      final re = spectrum[j * 2];
      final im = spectrum[j * 2 + 1];
      var mag = math.sqrt(re * re + im * im);
      if (mag < 1e-10) mag = 1e-10;
      mags[j] = 20.0 * math.log(mag) / math.ln10;
    }
    magnitudes.add(mags);
  }

  return SpectrogramData(
    magnitudes: magnitudes,
    sampleRate: sampleRate,
    freqBins: freqBins,
    duration: duration,
    maxFreq: sampleRate / 2.0,
    sliceCount: magnitudes.length,
  );
}

double? _estimateSpectralCutoffHz(SpectrogramData spectrum) {
  if (spectrum.magnitudes.isEmpty || spectrum.freqBins <= 0) return null;

  final averages = Float64List(spectrum.freqBins);
  for (final slice in spectrum.magnitudes) {
    final limit = math.min(slice.length, spectrum.freqBins);
    for (int i = 0; i < limit; i++) {
      averages[i] += slice[i];
    }
  }

  var peak = -double.infinity;
  final startBin = math.max(
    1,
    (20 / spectrum.maxFreq * spectrum.freqBins).floor(),
  );
  for (int i = startBin; i < averages.length; i++) {
    averages[i] /= spectrum.magnitudes.length;
    if (averages[i] > peak) peak = averages[i];
  }
  if (!peak.isFinite) return null;

  final threshold = peak - 60.0;
  var cutoffBin = 0;
  for (int i = averages.length - 1; i >= startBin; i--) {
    if (averages[i] >= threshold) {
      cutoffBin = i;
      break;
    }
  }
  if (cutoffBin <= 0) return null;
  return cutoffBin / spectrum.freqBins * spectrum.maxFreq;
}

Float64List _fft(Float64List realInput) {
  final n = realInput.length;
  final data = Float64List(n * 2);
  for (int i = 0; i < n; i++) {
    data[i * 2] = realInput[i];
  }

  int j = 0;
  for (int i = 0; i < n; i++) {
    if (i < j) {
      final tr = data[i * 2];
      final ti = data[i * 2 + 1];
      data[i * 2] = data[j * 2];
      data[i * 2 + 1] = data[j * 2 + 1];
      data[j * 2] = tr;
      data[j * 2 + 1] = ti;
    }
    int m = n >> 1;
    while (m >= 1 && j >= m) {
      j -= m;
      m >>= 1;
    }
    j += m;
  }

  for (int size = 2; size <= n; size <<= 1) {
    final halfSize = size >> 1;
    final angle = -2.0 * math.pi / size;
    final wRe = math.cos(angle);
    final wIm = math.sin(angle);

    for (int i = 0; i < n; i += size) {
      double curRe = 1.0;
      double curIm = 0.0;

      for (int k = 0; k < halfSize; k++) {
        final evenIdx = (i + k) * 2;
        final oddIdx = (i + k + halfSize) * 2;

        final tRe = curRe * data[oddIdx] - curIm * data[oddIdx + 1];
        final tIm = curRe * data[oddIdx + 1] + curIm * data[oddIdx];

        data[oddIdx] = data[evenIdx] - tRe;
        data[oddIdx + 1] = data[evenIdx + 1] - tIm;
        data[evenIdx] += tRe;
        data[evenIdx + 1] += tIm;

        final newRe = curRe * wRe - curIm * wIm;
        curIm = curRe * wIm + curIm * wRe;
        curRe = newRe;
      }
    }
  }

  return data;
}
