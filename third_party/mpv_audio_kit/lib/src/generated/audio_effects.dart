// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license
// that can be found in the LICENSE file.
//
// AUTO-GENERATED: do not edit by hand.
//
// The descriptions of the filters and of their options in the
// documentation comments are FFmpeg's (doc/filters.texi and the option
// help of libavfilter, https://ffmpeg.org) and keep FFmpeg's licenses: the
// LGPL, version 2.1 or later (FFmpeg's LICENSE.md), and for the option help of
// deesser, arnndn and hdcd the MIT or BSD terms of their source files; the BSD
// 3-Clause license above covers the rest of this file.
// ignore_for_file: unnecessary_ignore, constant_identifier_names, camel_case_types, non_constant_identifier_names

/// Values for the `detection` option of the `acompressor` audio filter.
enum AcompressorDetection {
  /// The `peak` option value.
  peak,

  /// The `rms` option value.
  rms;

  /// Wire-side string consumed by mpv.
  String get mpvValue => switch (this) {
    peak => 'peak',
    rms => 'rms',
  };

  /// Parses a mpv wire string back into a [AcompressorDetection].
  /// Unknown or empty input falls back to the first member.
  static AcompressorDetection fromMpv(String? raw) =>
      values.firstWhere((v) => v.mpvValue == raw, orElse: () => peak);
}

/// Values for the `link` option of the `acompressor` audio filter.
enum AcompressorLink {
  /// The `average` option value.
  average,

  /// The `maximum` option value.
  maximum;

  /// Wire-side string consumed by mpv.
  String get mpvValue => switch (this) {
    average => 'average',
    maximum => 'maximum',
  };

  /// Parses a mpv wire string back into a [AcompressorLink].
  /// Unknown or empty input falls back to the first member.
  static AcompressorLink fromMpv(String? raw) =>
      values.firstWhere((v) => v.mpvValue == raw, orElse: () => average);
}

/// Values for the `mode` option of the `acompressor` audio filter.
enum AcompressorMode {
  /// The `downward` option value.
  downward,

  /// The `upward` option value.
  upward;

  /// Wire-side string consumed by mpv.
  String get mpvValue => switch (this) {
    downward => 'downward',
    upward => 'upward',
  };

  /// Parses a mpv wire string back into a [AcompressorMode].
  /// Unknown or empty input falls back to the first member.
  static AcompressorMode fromMpv(String? raw) =>
      values.firstWhere((v) => v.mpvValue == raw, orElse: () => downward);
}

/// Values for the `mode` option of the `acrusher` audio filter.
enum AcrusherMode {
  /// linear
  lin,

  /// logarithmic
  log;

  /// Wire-side string consumed by mpv.
  String get mpvValue => switch (this) {
    lin => 'lin',
    log => 'log',
  };

  /// Parses a mpv wire string back into a [AcrusherMode].
  /// Unknown or empty input falls back to the first member.
  static AcrusherMode fromMpv(String? raw) =>
      values.firstWhere((v) => v.mpvValue == raw, orElse: () => lin);
}

/// Values for the `method` option of the `adeclick` audio filter.
enum AdeclickM {
  /// overlap-add
  add,

  /// overlap-add
  a,

  /// overlap-save
  save,

  /// overlap-save
  s;

  /// Wire-side string consumed by mpv.
  String get mpvValue => switch (this) {
    add => 'add',
    a => 'a',
    save => 'save',
    s => 's',
  };

  /// Parses a mpv wire string back into a [AdeclickM].
  /// Unknown or empty input falls back to the first member.
  static AdeclickM fromMpv(String? raw) =>
      values.firstWhere((v) => v.mpvValue == raw, orElse: () => add);
}

/// Values for the `method` option of the `adeclip` audio filter.
enum AdeclipM {
  /// overlap-add
  add,

  /// overlap-add
  a,

  /// overlap-save
  save,

  /// overlap-save
  s;

  /// Wire-side string consumed by mpv.
  String get mpvValue => switch (this) {
    add => 'add',
    a => 'a',
    save => 'save',
    s => 's',
  };

  /// Parses a mpv wire string back into a [AdeclipM].
  /// Unknown or empty input falls back to the first member.
  static AdeclipM fromMpv(String? raw) =>
      values.firstWhere((v) => v.mpvValue == raw, orElse: () => add);
}

/// Values for the `type` option of the `adenorm` audio filter.
enum AdenormType {
  /// The `dc` option value.
  dc,

  /// The `ac` option value.
  ac,

  /// The `square` option value.
  square,

  /// The `pulse` option value.
  pulse;

  /// Wire-side string consumed by mpv.
  String get mpvValue => switch (this) {
    dc => 'dc',
    ac => 'ac',
    square => 'square',
    pulse => 'pulse',
  };

  /// Parses a mpv wire string back into a [AdenormType].
  /// Unknown or empty input falls back to the first member.
  static AdenormType fromMpv(String? raw) =>
      values.firstWhere((v) => v.mpvValue == raw, orElse: () => dc);
}

/// Values for the `auto` option of the `adynamicequalizer` audio filter.
enum AdynamicequalizerAuto {
  /// The `disabled` option value.
  disabled,

  /// The `off` option value.
  off,

  /// The `on` option value.
  on_,

  /// The `adaptive` option value.
  adaptive;

  /// Wire-side string consumed by mpv.
  String get mpvValue => switch (this) {
    disabled => 'disabled',
    off => 'off',
    on_ => 'on',
    adaptive => 'adaptive',
  };

  /// Parses a mpv wire string back into a [AdynamicequalizerAuto].
  /// Unknown or empty input falls back to the first member.
  static AdynamicequalizerAuto fromMpv(String? raw) =>
      values.firstWhere((v) => v.mpvValue == raw, orElse: () => disabled);
}

/// Values for the `dftype` option of the `adynamicequalizer` audio filter.
enum AdynamicequalizerDftype {
  /// The `bandpass` option value.
  bandpass,

  /// The `lowpass` option value.
  lowpass,

  /// The `highpass` option value.
  highpass,

  /// The `peak` option value.
  peak;

  /// Wire-side string consumed by mpv.
  String get mpvValue => switch (this) {
    bandpass => 'bandpass',
    lowpass => 'lowpass',
    highpass => 'highpass',
    peak => 'peak',
  };

  /// Parses a mpv wire string back into a [AdynamicequalizerDftype].
  /// Unknown or empty input falls back to the first member.
  static AdynamicequalizerDftype fromMpv(String? raw) =>
      values.firstWhere((v) => v.mpvValue == raw, orElse: () => bandpass);
}

/// Values for the `mode` option of the `adynamicequalizer` audio filter.
enum AdynamicequalizerMode {
  /// The `listen` option value.
  listen,

  /// The `cutbelow` option value.
  cutbelow,

  /// The `cutabove` option value.
  cutabove,

  /// The `boostbelow` option value.
  boostbelow,

  /// The `boostabove` option value.
  boostabove;

  /// Wire-side string consumed by mpv.
  String get mpvValue => switch (this) {
    listen => 'listen',
    cutbelow => 'cutbelow',
    cutabove => 'cutabove',
    boostbelow => 'boostbelow',
    boostabove => 'boostabove',
  };

  /// Parses a mpv wire string back into a [AdynamicequalizerMode].
  /// Unknown or empty input falls back to the first member.
  static AdynamicequalizerMode fromMpv(String? raw) =>
      values.firstWhere((v) => v.mpvValue == raw, orElse: () => listen);
}

/// Values for the `precision` option of the `adynamicequalizer` audio filter.
enum AdynamicequalizerPrecision {
  /// set auto processing precision
  auto,

  /// set single-floating point processing precision
  float,

  /// set double-floating point processing precision
  double_;

  /// Wire-side string consumed by mpv.
  String get mpvValue => switch (this) {
    auto => 'auto',
    float => 'float',
    double_ => 'double',
  };

  /// Parses a mpv wire string back into a [AdynamicequalizerPrecision].
  /// Unknown or empty input falls back to the first member.
  static AdynamicequalizerPrecision fromMpv(String? raw) =>
      values.firstWhere((v) => v.mpvValue == raw, orElse: () => auto);
}

/// Values for the `tftype` option of the `adynamicequalizer` audio filter.
enum AdynamicequalizerTftype {
  /// The `bell` option value.
  bell,

  /// The `lowshelf` option value.
  lowshelf,

  /// The `highshelf` option value.
  highshelf;

  /// Wire-side string consumed by mpv.
  String get mpvValue => switch (this) {
    bell => 'bell',
    lowshelf => 'lowshelf',
    highshelf => 'highshelf',
  };

  /// Parses a mpv wire string back into a [AdynamicequalizerTftype].
  /// Unknown or empty input falls back to the first member.
  static AdynamicequalizerTftype fromMpv(String? raw) =>
      values.firstWhere((v) => v.mpvValue == raw, orElse: () => bell);
}

/// Values for the `mode` option of the `aemphasis` audio filter.
enum AemphasisMode {
  /// The `reproduction` option value.
  reproduction,

  /// The `production` option value.
  production;

  /// Wire-side string consumed by mpv.
  String get mpvValue => switch (this) {
    reproduction => 'reproduction',
    production => 'production',
  };

  /// Parses a mpv wire string back into a [AemphasisMode].
  /// Unknown or empty input falls back to the first member.
  static AemphasisMode fromMpv(String? raw) =>
      values.firstWhere((v) => v.mpvValue == raw, orElse: () => reproduction);
}

/// Values for the `type` option of the `aemphasis` audio filter.
enum AemphasisType {
  /// Columbia
  col,

  /// EMI
  emi,

  /// BSI (78RPM)
  bsi,

  /// RIAA
  riaa,

  /// Compact Disc (CD)
  cd,

  /// 50µs (FM)
  n50fm,

  /// 75µs (FM)
  n75fm,

  /// 50µs (FM-KF)
  n50kf,

  /// 75µs (FM-KF)
  n75kf;

  /// Wire-side string consumed by mpv.
  String get mpvValue => switch (this) {
    col => 'col',
    emi => 'emi',
    bsi => 'bsi',
    riaa => 'riaa',
    cd => 'cd',
    n50fm => '50fm',
    n75fm => '75fm',
    n50kf => '50kf',
    n75kf => '75kf',
  };

  /// Parses a mpv wire string back into a [AemphasisType].
  /// Unknown or empty input falls back to the first member.
  static AemphasisType fromMpv(String? raw) =>
      values.firstWhere((v) => v.mpvValue == raw, orElse: () => col);
}

/// Values for the `curve` option of the `afade` audio filter.
enum AfadeCurve {
  /// no fade; keep audio as-is
  nofade,

  /// linear slope
  tri,

  /// quarter of sine wave
  qsin,

  /// exponential sine wave
  esin,

  /// half of sine wave
  hsin,

  /// logarithmic
  log,

  /// inverted parabola
  ipar,

  /// quadratic
  qua,

  /// cubic
  cub,

  /// square root
  squ,

  /// cubic root
  cbr,

  /// parabola
  par,

  /// exponential
  exp,

  /// inverted quarter of sine wave
  iqsin,

  /// inverted half of sine wave
  ihsin,

  /// double-exponential seat
  dese,

  /// double-exponential sigmoid
  desi,

  /// logistic sigmoid
  losi,

  /// sine cardinal function
  sinc,

  /// inverted sine cardinal function
  isinc,

  /// quartic
  quat,

  /// quartic root
  quatr,

  /// squared quarter of sine wave
  qsin2,

  /// squared half of sine wave
  hsin2;

  /// Wire-side string consumed by mpv.
  String get mpvValue => switch (this) {
    nofade => 'nofade',
    tri => 'tri',
    qsin => 'qsin',
    esin => 'esin',
    hsin => 'hsin',
    log => 'log',
    ipar => 'ipar',
    qua => 'qua',
    cub => 'cub',
    squ => 'squ',
    cbr => 'cbr',
    par => 'par',
    exp => 'exp',
    iqsin => 'iqsin',
    ihsin => 'ihsin',
    dese => 'dese',
    desi => 'desi',
    losi => 'losi',
    sinc => 'sinc',
    isinc => 'isinc',
    quat => 'quat',
    quatr => 'quatr',
    qsin2 => 'qsin2',
    hsin2 => 'hsin2',
  };

  /// Parses a mpv wire string back into a [AfadeCurve].
  /// Unknown or empty input falls back to the first member.
  static AfadeCurve fromMpv(String? raw) =>
      values.firstWhere((v) => v.mpvValue == raw, orElse: () => nofade);
}

/// Values for the `type` option of the `afade` audio filter.
enum AfadeType {
  /// fade-in
  in_,

  /// fade-out
  out;

  /// Wire-side string consumed by mpv.
  String get mpvValue => switch (this) {
    in_ => 'in',
    out => 'out',
  };

  /// Parses a mpv wire string back into a [AfadeType].
  /// Unknown or empty input falls back to the first member.
  static AfadeType fromMpv(String? raw) =>
      values.firstWhere((v) => v.mpvValue == raw, orElse: () => in_);
}

/// Values for the `noise_link` option of the `afftdn` audio filter.
enum AfftdnLink {
  /// none
  none,

  /// min
  min,

  /// max
  max,

  /// average
  average;

  /// Wire-side string consumed by mpv.
  String get mpvValue => switch (this) {
    none => 'none',
    min => 'min',
    max => 'max',
    average => 'average',
  };

  /// Parses a mpv wire string back into a [AfftdnLink].
  /// Unknown or empty input falls back to the first member.
  static AfftdnLink fromMpv(String? raw) =>
      values.firstWhere((v) => v.mpvValue == raw, orElse: () => none);
}

/// Values for the `output_mode` option of the `afftdn` audio filter.
enum AfftdnMode {
  /// input
  input,

  /// input
  i,

  /// output
  output,

  /// output
  o,

  /// noise
  noise,

  /// noise
  n;

  /// Wire-side string consumed by mpv.
  String get mpvValue => switch (this) {
    input => 'input',
    i => 'i',
    output => 'output',
    o => 'o',
    noise => 'noise',
    n => 'n',
  };

  /// Parses a mpv wire string back into a [AfftdnMode].
  /// Unknown or empty input falls back to the first member.
  static AfftdnMode fromMpv(String? raw) =>
      values.firstWhere((v) => v.mpvValue == raw, orElse: () => input);
}

/// Values for the `sample_noise` option of the `afftdn` audio filter.
enum AfftdnSample {
  /// none
  none,

  /// start
  start,

  /// start
  begin,

  /// stop
  stop,

  /// stop
  end;

  /// Wire-side string consumed by mpv.
  String get mpvValue => switch (this) {
    none => 'none',
    start => 'start',
    begin => 'begin',
    stop => 'stop',
    end => 'end',
  };

  /// Parses a mpv wire string back into a [AfftdnSample].
  /// Unknown or empty input falls back to the first member.
  static AfftdnSample fromMpv(String? raw) =>
      values.firstWhere((v) => v.mpvValue == raw, orElse: () => none);
}

/// Values for the `noise_type` option of the `afftdn` audio filter.
enum AfftdnType {
  /// white noise
  white,

  /// white noise
  w,

  /// vinyl noise
  vinyl,

  /// vinyl noise
  v,

  /// shellac noise
  shellac,

  /// shellac noise
  s,

  /// custom noise
  custom,

  /// custom noise
  c;

  /// Wire-side string consumed by mpv.
  String get mpvValue => switch (this) {
    white => 'white',
    w => 'w',
    vinyl => 'vinyl',
    v => 'v',
    shellac => 'shellac',
    s => 's',
    custom => 'custom',
    c => 'c',
  };

  /// Parses a mpv wire string back into a [AfftdnType].
  /// Unknown or empty input falls back to the first member.
  static AfftdnType fromMpv(String? raw) =>
      values.firstWhere((v) => v.mpvValue == raw, orElse: () => white);
}

/// Values for the `win_func` option of the `afftfilt` audio filter.
enum AfftfiltWinFunc {
  /// Rectangular
  rect,

  /// Bartlett
  bartlett,

  /// Hann
  hann,

  /// Hanning
  hanning,

  /// Hamming
  hamming,

  /// Blackman
  blackman,

  /// Welch
  welch,

  /// Flat-top
  flattop,

  /// Blackman-Harris
  bharris,

  /// Blackman-Nuttall
  bnuttall,

  /// Bartlett-Hann
  bhann,

  /// Sine
  sine,

  /// Nuttall
  nuttall,

  /// Lanczos
  lanczos,

  /// Gauss
  gauss,

  /// Tukey
  tukey,

  /// Dolph-Chebyshev
  dolph,

  /// Cauchy
  cauchy,

  /// Parzen
  parzen,

  /// Poisson
  poisson,

  /// Bohman
  bohman,

  /// Kaiser
  kaiser;

  /// Wire-side string consumed by mpv.
  String get mpvValue => switch (this) {
    rect => 'rect',
    bartlett => 'bartlett',
    hann => 'hann',
    hanning => 'hanning',
    hamming => 'hamming',
    blackman => 'blackman',
    welch => 'welch',
    flattop => 'flattop',
    bharris => 'bharris',
    bnuttall => 'bnuttall',
    bhann => 'bhann',
    sine => 'sine',
    nuttall => 'nuttall',
    lanczos => 'lanczos',
    gauss => 'gauss',
    tukey => 'tukey',
    dolph => 'dolph',
    cauchy => 'cauchy',
    parzen => 'parzen',
    poisson => 'poisson',
    bohman => 'bohman',
    kaiser => 'kaiser',
  };

  /// Parses a mpv wire string back into a [AfftfiltWinFunc].
  /// Unknown or empty input falls back to the first member.
  static AfftfiltWinFunc fromMpv(String? raw) =>
      values.firstWhere((v) => v.mpvValue == raw, orElse: () => rect);
}

/// Values for the `wavet` option of the `afwtdn` audio filter.
enum AfwtdnWavet {
  /// sym2
  sym2,

  /// sym4
  sym4,

  /// rbior68
  rbior68,

  /// deb10
  deb10,

  /// sym10
  sym10,

  /// coif5
  coif5,

  /// bl3
  bl3;

  /// Wire-side string consumed by mpv.
  String get mpvValue => switch (this) {
    sym2 => 'sym2',
    sym4 => 'sym4',
    rbior68 => 'rbior68',
    deb10 => 'deb10',
    sym10 => 'sym10',
    coif5 => 'coif5',
    bl3 => 'bl3',
  };

  /// Parses a mpv wire string back into a [AfwtdnWavet].
  /// Unknown or empty input falls back to the first member.
  static AfwtdnWavet fromMpv(String? raw) =>
      values.firstWhere((v) => v.mpvValue == raw, orElse: () => sym2);
}

/// Values for the `detection` option of the `agate` audio filter.
enum AgateDetection {
  /// The `peak` option value.
  peak,

  /// The `rms` option value.
  rms;

  /// Wire-side string consumed by mpv.
  String get mpvValue => switch (this) {
    peak => 'peak',
    rms => 'rms',
  };

  /// Parses a mpv wire string back into a [AgateDetection].
  /// Unknown or empty input falls back to the first member.
  static AgateDetection fromMpv(String? raw) =>
      values.firstWhere((v) => v.mpvValue == raw, orElse: () => peak);
}

/// Values for the `link` option of the `agate` audio filter.
enum AgateLink {
  /// The `average` option value.
  average,

  /// The `maximum` option value.
  maximum;

  /// Wire-side string consumed by mpv.
  String get mpvValue => switch (this) {
    average => 'average',
    maximum => 'maximum',
  };

  /// Parses a mpv wire string back into a [AgateLink].
  /// Unknown or empty input falls back to the first member.
  static AgateLink fromMpv(String? raw) =>
      values.firstWhere((v) => v.mpvValue == raw, orElse: () => average);
}

/// Values for the `mode` option of the `agate` audio filter.
enum AgateMode {
  /// The `downward` option value.
  downward,

  /// The `upward` option value.
  upward;

  /// Wire-side string consumed by mpv.
  String get mpvValue => switch (this) {
    downward => 'downward',
    upward => 'upward',
  };

  /// Parses a mpv wire string back into a [AgateMode].
  /// Unknown or empty input falls back to the first member.
  static AgateMode fromMpv(String? raw) =>
      values.firstWhere((v) => v.mpvValue == raw, orElse: () => downward);
}

/// Values for the `format` option of the `aiir` audio filter.
enum AiirFormat {
  /// lattice-ladder function
  ll,

  /// analog transfer function
  sf,

  /// digital transfer function
  tf,

  /// Z-plane zeros/poles
  zp,

  /// Z-plane zeros/poles (polar radians)
  pr,

  /// Z-plane zeros/poles (polar degrees)
  pd,

  /// S-plane zeros/poles
  sp;

  /// Wire-side string consumed by mpv.
  String get mpvValue => switch (this) {
    ll => 'll',
    sf => 'sf',
    tf => 'tf',
    zp => 'zp',
    pr => 'pr',
    pd => 'pd',
    sp => 'sp',
  };

  /// Parses a mpv wire string back into a [AiirFormat].
  /// Unknown or empty input falls back to the first member.
  static AiirFormat fromMpv(String? raw) =>
      values.firstWhere((v) => v.mpvValue == raw, orElse: () => ll);
}

/// Values for the `precision` option of the `aiir` audio filter.
enum AiirPrecision {
  /// double-precision floating-point
  dbl,

  /// single-precision floating-point
  flt,

  /// 32-bit integers
  i32,

  /// 16-bit integers
  i16;

  /// Wire-side string consumed by mpv.
  String get mpvValue => switch (this) {
    dbl => 'dbl',
    flt => 'flt',
    i32 => 'i32',
    i16 => 'i16',
  };

  /// Parses a mpv wire string back into a [AiirPrecision].
  /// Unknown or empty input falls back to the first member.
  static AiirPrecision fromMpv(String? raw) =>
      values.firstWhere((v) => v.mpvValue == raw, orElse: () => dbl);
}

/// Values for the `process` option of the `aiir` audio filter.
enum AiirProcess {
  /// direct
  d,

  /// serial
  s,

  /// parallel
  p;

  /// Wire-side string consumed by mpv.
  String get mpvValue => switch (this) {
    d => 'd',
    s => 's',
    p => 'p',
  };

  /// Parses a mpv wire string back into a [AiirProcess].
  /// Unknown or empty input falls back to the first member.
  static AiirProcess fromMpv(String? raw) =>
      values.firstWhere((v) => v.mpvValue == raw, orElse: () => d);
}

/// Values for the `precision` option of the `allpass` audio filter.
enum AllpassPrecision {
  /// automatic
  auto,

  /// signed 16-bit
  s16,

  /// signed 32-bit
  s32,

  /// floating-point single
  f32,

  /// floating-point double
  f64;

  /// Wire-side string consumed by mpv.
  String get mpvValue => switch (this) {
    auto => 'auto',
    s16 => 's16',
    s32 => 's32',
    f32 => 'f32',
    f64 => 'f64',
  };

  /// Parses a mpv wire string back into a [AllpassPrecision].
  /// Unknown or empty input falls back to the first member.
  static AllpassPrecision fromMpv(String? raw) =>
      values.firstWhere((v) => v.mpvValue == raw, orElse: () => auto);
}

/// Values for the `transform` option of the `allpass` audio filter.
enum AllpassTransformType {
  /// direct form I
  di,

  /// direct form II
  dii,

  /// transposed direct form I
  tdi,

  /// transposed direct form II
  tdii,

  /// lattice-ladder form
  latt,

  /// state variable filter form
  svf,

  /// zero-delay filter form
  zdf;

  /// Wire-side string consumed by mpv.
  String get mpvValue => switch (this) {
    di => 'di',
    dii => 'dii',
    tdi => 'tdi',
    tdii => 'tdii',
    latt => 'latt',
    svf => 'svf',
    zdf => 'zdf',
  };

  /// Parses a mpv wire string back into a [AllpassTransformType].
  /// Unknown or empty input falls back to the first member.
  static AllpassTransformType fromMpv(String? raw) =>
      values.firstWhere((v) => v.mpvValue == raw, orElse: () => di);
}

/// Values for the `width_type` option of the `allpass` audio filter.
enum AllpassWidthType {
  /// Hz
  h,

  /// Q-Factor
  q,

  /// octave
  o,

  /// slope
  s,

  /// kHz
  k;

  /// Wire-side string consumed by mpv.
  String get mpvValue => switch (this) {
    h => 'h',
    q => 'q',
    o => 'o',
    s => 's',
    k => 'k',
  };

  /// Parses a mpv wire string back into a [AllpassWidthType].
  /// Unknown or empty input falls back to the first member.
  static AllpassWidthType fromMpv(String? raw) =>
      values.firstWhere((v) => v.mpvValue == raw, orElse: () => h);
}

/// Values for the `fscale` option of the `anequalizer` audio filter.
enum AnequalizerFscale {
  /// linear
  lin,

  /// logarithmic
  log;

  /// Wire-side string consumed by mpv.
  String get mpvValue => switch (this) {
    lin => 'lin',
    log => 'log',
  };

  /// Parses a mpv wire string back into a [AnequalizerFscale].
  /// Unknown or empty input falls back to the first member.
  static AnequalizerFscale fromMpv(String? raw) =>
      values.firstWhere((v) => v.mpvValue == raw, orElse: () => lin);
}

/// Values for the `output` option of the `anlmdn` audio filter.
enum AnlmdnMode {
  /// input
  i,

  /// output
  o,

  /// noise
  n;

  /// Wire-side string consumed by mpv.
  String get mpvValue => switch (this) {
    i => 'i',
    o => 'o',
    n => 'n',
  };

  /// Parses a mpv wire string back into a [AnlmdnMode].
  /// Unknown or empty input falls back to the first member.
  static AnlmdnMode fromMpv(String? raw) =>
      values.firstWhere((v) => v.mpvValue == raw, orElse: () => i);
}

/// Values for the `type` option of the `aphaser` audio filter.
enum AphaserType {
  /// The `triangular` option value.
  triangular,

  /// The `t` option value.
  t,

  /// The `sinusoidal` option value.
  sinusoidal,

  /// The `s` option value.
  s;

  /// Wire-side string consumed by mpv.
  String get mpvValue => switch (this) {
    triangular => 'triangular',
    t => 't',
    sinusoidal => 'sinusoidal',
    s => 's',
  };

  /// Parses a mpv wire string back into a [AphaserType].
  /// Unknown or empty input falls back to the first member.
  static AphaserType fromMpv(String? raw) =>
      values.firstWhere((v) => v.mpvValue == raw, orElse: () => triangular);
}

/// Values for the `mode` option of the `apulsator` audio filter.
enum ApulsatorMode {
  /// The `sine` option value.
  sine,

  /// The `triangle` option value.
  triangle,

  /// The `square` option value.
  square,

  /// The `sawup` option value.
  sawup,

  /// The `sawdown` option value.
  sawdown;

  /// Wire-side string consumed by mpv.
  String get mpvValue => switch (this) {
    sine => 'sine',
    triangle => 'triangle',
    square => 'square',
    sawup => 'sawup',
    sawdown => 'sawdown',
  };

  /// Parses a mpv wire string back into a [ApulsatorMode].
  /// Unknown or empty input falls back to the first member.
  static ApulsatorMode fromMpv(String? raw) =>
      values.firstWhere((v) => v.mpvValue == raw, orElse: () => sine);
}

/// Values for the `timing` option of the `apulsator` audio filter.
enum ApulsatorTiming {
  /// The `bpm` option value.
  bpm,

  /// The `ms` option value.
  ms,

  /// The `hz` option value.
  hz;

  /// Wire-side string consumed by mpv.
  String get mpvValue => switch (this) {
    bpm => 'bpm',
    ms => 'ms',
    hz => 'hz',
  };

  /// Parses a mpv wire string back into a [ApulsatorTiming].
  /// Unknown or empty input falls back to the first member.
  static ApulsatorTiming fromMpv(String? raw) =>
      values.firstWhere((v) => v.mpvValue == raw, orElse: () => bpm);
}

/// Values for the `type` option of the `asoftclip` audio filter.
enum AsoftclipTypes {
  /// The `hard` option value.
  hard,

  /// The `tanh` option value.
  tanh,

  /// The `atan` option value.
  atan,

  /// The `cubic` option value.
  cubic,

  /// The `exp` option value.
  exp,

  /// The `alg` option value.
  alg,

  /// The `quintic` option value.
  quintic,

  /// The `sin` option value.
  sin,

  /// The `erf` option value.
  erf;

  /// Wire-side string consumed by mpv.
  String get mpvValue => switch (this) {
    hard => 'hard',
    tanh => 'tanh',
    atan => 'atan',
    cubic => 'cubic',
    exp => 'exp',
    alg => 'alg',
    quintic => 'quintic',
    sin => 'sin',
    erf => 'erf',
  };

  /// Parses a mpv wire string back into a [AsoftclipTypes].
  /// Unknown or empty input falls back to the first member.
  static AsoftclipTypes fromMpv(String? raw) =>
      values.firstWhere((v) => v.mpvValue == raw, orElse: () => hard);
}

/// Values for the `precision` option of the `bandpass` audio filter.
enum BandpassPrecision {
  /// automatic
  auto,

  /// signed 16-bit
  s16,

  /// signed 32-bit
  s32,

  /// floating-point single
  f32,

  /// floating-point double
  f64;

  /// Wire-side string consumed by mpv.
  String get mpvValue => switch (this) {
    auto => 'auto',
    s16 => 's16',
    s32 => 's32',
    f32 => 'f32',
    f64 => 'f64',
  };

  /// Parses a mpv wire string back into a [BandpassPrecision].
  /// Unknown or empty input falls back to the first member.
  static BandpassPrecision fromMpv(String? raw) =>
      values.firstWhere((v) => v.mpvValue == raw, orElse: () => auto);
}

/// Values for the `transform` option of the `bandpass` audio filter.
enum BandpassTransformType {
  /// direct form I
  di,

  /// direct form II
  dii,

  /// transposed direct form I
  tdi,

  /// transposed direct form II
  tdii,

  /// lattice-ladder form
  latt,

  /// state variable filter form
  svf,

  /// zero-delay filter form
  zdf;

  /// Wire-side string consumed by mpv.
  String get mpvValue => switch (this) {
    di => 'di',
    dii => 'dii',
    tdi => 'tdi',
    tdii => 'tdii',
    latt => 'latt',
    svf => 'svf',
    zdf => 'zdf',
  };

  /// Parses a mpv wire string back into a [BandpassTransformType].
  /// Unknown or empty input falls back to the first member.
  static BandpassTransformType fromMpv(String? raw) =>
      values.firstWhere((v) => v.mpvValue == raw, orElse: () => di);
}

/// Values for the `width_type` option of the `bandpass` audio filter.
enum BandpassWidthType {
  /// Hz
  h,

  /// Q-Factor
  q,

  /// octave
  o,

  /// slope
  s,

  /// kHz
  k;

  /// Wire-side string consumed by mpv.
  String get mpvValue => switch (this) {
    h => 'h',
    q => 'q',
    o => 'o',
    s => 's',
    k => 'k',
  };

  /// Parses a mpv wire string back into a [BandpassWidthType].
  /// Unknown or empty input falls back to the first member.
  static BandpassWidthType fromMpv(String? raw) =>
      values.firstWhere((v) => v.mpvValue == raw, orElse: () => h);
}

/// Values for the `precision` option of the `bandreject` audio filter.
enum BandrejectPrecision {
  /// automatic
  auto,

  /// signed 16-bit
  s16,

  /// signed 32-bit
  s32,

  /// floating-point single
  f32,

  /// floating-point double
  f64;

  /// Wire-side string consumed by mpv.
  String get mpvValue => switch (this) {
    auto => 'auto',
    s16 => 's16',
    s32 => 's32',
    f32 => 'f32',
    f64 => 'f64',
  };

  /// Parses a mpv wire string back into a [BandrejectPrecision].
  /// Unknown or empty input falls back to the first member.
  static BandrejectPrecision fromMpv(String? raw) =>
      values.firstWhere((v) => v.mpvValue == raw, orElse: () => auto);
}

/// Values for the `transform` option of the `bandreject` audio filter.
enum BandrejectTransformType {
  /// direct form I
  di,

  /// direct form II
  dii,

  /// transposed direct form I
  tdi,

  /// transposed direct form II
  tdii,

  /// lattice-ladder form
  latt,

  /// state variable filter form
  svf,

  /// zero-delay filter form
  zdf;

  /// Wire-side string consumed by mpv.
  String get mpvValue => switch (this) {
    di => 'di',
    dii => 'dii',
    tdi => 'tdi',
    tdii => 'tdii',
    latt => 'latt',
    svf => 'svf',
    zdf => 'zdf',
  };

  /// Parses a mpv wire string back into a [BandrejectTransformType].
  /// Unknown or empty input falls back to the first member.
  static BandrejectTransformType fromMpv(String? raw) =>
      values.firstWhere((v) => v.mpvValue == raw, orElse: () => di);
}

/// Values for the `width_type` option of the `bandreject` audio filter.
enum BandrejectWidthType {
  /// Hz
  h,

  /// Q-Factor
  q,

  /// octave
  o,

  /// slope
  s,

  /// kHz
  k;

  /// Wire-side string consumed by mpv.
  String get mpvValue => switch (this) {
    h => 'h',
    q => 'q',
    o => 'o',
    s => 's',
    k => 'k',
  };

  /// Parses a mpv wire string back into a [BandrejectWidthType].
  /// Unknown or empty input falls back to the first member.
  static BandrejectWidthType fromMpv(String? raw) =>
      values.firstWhere((v) => v.mpvValue == raw, orElse: () => h);
}

/// Values for the `precision` option of the `bass` audio filter.
enum BassPrecision {
  /// automatic
  auto,

  /// signed 16-bit
  s16,

  /// signed 32-bit
  s32,

  /// floating-point single
  f32,

  /// floating-point double
  f64;

  /// Wire-side string consumed by mpv.
  String get mpvValue => switch (this) {
    auto => 'auto',
    s16 => 's16',
    s32 => 's32',
    f32 => 'f32',
    f64 => 'f64',
  };

  /// Parses a mpv wire string back into a [BassPrecision].
  /// Unknown or empty input falls back to the first member.
  static BassPrecision fromMpv(String? raw) =>
      values.firstWhere((v) => v.mpvValue == raw, orElse: () => auto);
}

/// Values for the `transform` option of the `bass` audio filter.
enum BassTransformType {
  /// direct form I
  di,

  /// direct form II
  dii,

  /// transposed direct form I
  tdi,

  /// transposed direct form II
  tdii,

  /// lattice-ladder form
  latt,

  /// state variable filter form
  svf,

  /// zero-delay filter form
  zdf;

  /// Wire-side string consumed by mpv.
  String get mpvValue => switch (this) {
    di => 'di',
    dii => 'dii',
    tdi => 'tdi',
    tdii => 'tdii',
    latt => 'latt',
    svf => 'svf',
    zdf => 'zdf',
  };

  /// Parses a mpv wire string back into a [BassTransformType].
  /// Unknown or empty input falls back to the first member.
  static BassTransformType fromMpv(String? raw) =>
      values.firstWhere((v) => v.mpvValue == raw, orElse: () => di);
}

/// Values for the `width_type` option of the `bass` audio filter.
enum BassWidthType {
  /// Hz
  h,

  /// Q-Factor
  q,

  /// octave
  o,

  /// slope
  s,

  /// kHz
  k;

  /// Wire-side string consumed by mpv.
  String get mpvValue => switch (this) {
    h => 'h',
    q => 'q',
    o => 'o',
    s => 's',
    k => 'k',
  };

  /// Parses a mpv wire string back into a [BassWidthType].
  /// Unknown or empty input falls back to the first member.
  static BassWidthType fromMpv(String? raw) =>
      values.firstWhere((v) => v.mpvValue == raw, orElse: () => h);
}

/// Values for the `precision` option of the `biquad` audio filter.
enum BiquadPrecision {
  /// automatic
  auto,

  /// signed 16-bit
  s16,

  /// signed 32-bit
  s32,

  /// floating-point single
  f32,

  /// floating-point double
  f64;

  /// Wire-side string consumed by mpv.
  String get mpvValue => switch (this) {
    auto => 'auto',
    s16 => 's16',
    s32 => 's32',
    f32 => 'f32',
    f64 => 'f64',
  };

  /// Parses a mpv wire string back into a [BiquadPrecision].
  /// Unknown or empty input falls back to the first member.
  static BiquadPrecision fromMpv(String? raw) =>
      values.firstWhere((v) => v.mpvValue == raw, orElse: () => auto);
}

/// Values for the `transform` option of the `biquad` audio filter.
enum BiquadTransformType {
  /// direct form I
  di,

  /// direct form II
  dii,

  /// transposed direct form I
  tdi,

  /// transposed direct form II
  tdii,

  /// lattice-ladder form
  latt,

  /// state variable filter form
  svf,

  /// zero-delay filter form
  zdf;

  /// Wire-side string consumed by mpv.
  String get mpvValue => switch (this) {
    di => 'di',
    dii => 'dii',
    tdi => 'tdi',
    tdii => 'tdii',
    latt => 'latt',
    svf => 'svf',
    zdf => 'zdf',
  };

  /// Parses a mpv wire string back into a [BiquadTransformType].
  /// Unknown or empty input falls back to the first member.
  static BiquadTransformType fromMpv(String? raw) =>
      values.firstWhere((v) => v.mpvValue == raw, orElse: () => di);
}

/// Values for the `s` option of the `deesser` audio filter.
enum DeesserMode {
  /// input
  i,

  /// output
  o,

  /// ess
  e;

  /// Wire-side string consumed by mpv.
  String get mpvValue => switch (this) {
    i => 'i',
    o => 'o',
    e => 'e',
  };

  /// Parses a mpv wire string back into a [DeesserMode].
  /// Unknown or empty input falls back to the first member.
  static DeesserMode fromMpv(String? raw) =>
      values.firstWhere((v) => v.mpvValue == raw, orElse: () => i);
}

/// Values for the `gauge` option of the `ebur128` audio filter.
enum Ebur128Gaugetype {
  /// display momentary value
  momentary,

  /// display momentary value
  m,

  /// display short-term value
  shortterm,

  /// display short-term value
  s;

  /// Wire-side string consumed by mpv.
  String get mpvValue => switch (this) {
    momentary => 'momentary',
    m => 'm',
    shortterm => 'shortterm',
    s => 's',
  };

  /// Parses a mpv wire string back into a [Ebur128Gaugetype].
  /// Unknown or empty input falls back to the first member.
  static Ebur128Gaugetype fromMpv(String? raw) =>
      values.firstWhere((v) => v.mpvValue == raw, orElse: () => momentary);
}

/// Values for the `framelog` option of the `ebur128` audio filter.
enum Ebur128Level {
  /// logging disabled
  quiet,

  /// information logging level
  info,

  /// verbose logging level
  verbose;

  /// Wire-side string consumed by mpv.
  String get mpvValue => switch (this) {
    quiet => 'quiet',
    info => 'info',
    verbose => 'verbose',
  };

  /// Parses a mpv wire string back into a [Ebur128Level].
  /// Unknown or empty input falls back to the first member.
  static Ebur128Level fromMpv(String? raw) =>
      values.firstWhere((v) => v.mpvValue == raw, orElse: () => quiet);
}

/// Values for the `peak` option of the `ebur128` audio filter.
enum Ebur128Mode {
  /// disable any peak mode
  none,

  /// enable peak-sample mode
  sample,

  /// enable true-peak mode
  true_;

  /// Wire-side string consumed by mpv.
  String get mpvValue => switch (this) {
    none => 'none',
    sample => 'sample',
    true_ => 'true',
  };

  /// Parses a mpv wire string back into a [Ebur128Mode].
  /// Unknown or empty input falls back to the first member.
  static Ebur128Mode fromMpv(String? raw) =>
      values.firstWhere((v) => v.mpvValue == raw, orElse: () => none);
}

/// Values for the `scale` option of the `ebur128` audio filter.
enum Ebur128Scaletype {
  /// display absolute values (LUFS)
  absolute,

  /// display absolute values (LUFS)
  lufs,

  /// display values relative to target (LU)
  relative,

  /// display values relative to target (LU)
  lu;

  /// Wire-side string consumed by mpv.
  String get mpvValue => switch (this) {
    absolute => 'absolute',
    lufs => 'LUFS',
    relative => 'relative',
    lu => 'LU',
  };

  /// Parses a mpv wire string back into a [Ebur128Scaletype].
  /// Unknown or empty input falls back to the first member.
  static Ebur128Scaletype fromMpv(String? raw) =>
      values.firstWhere((v) => v.mpvValue == raw, orElse: () => absolute);
}

/// Values for the `precision` option of the `equalizer` audio filter.
enum EqualizerPrecision {
  /// automatic
  auto,

  /// signed 16-bit
  s16,

  /// signed 32-bit
  s32,

  /// floating-point single
  f32,

  /// floating-point double
  f64;

  /// Wire-side string consumed by mpv.
  String get mpvValue => switch (this) {
    auto => 'auto',
    s16 => 's16',
    s32 => 's32',
    f32 => 'f32',
    f64 => 'f64',
  };

  /// Parses a mpv wire string back into a [EqualizerPrecision].
  /// Unknown or empty input falls back to the first member.
  static EqualizerPrecision fromMpv(String? raw) =>
      values.firstWhere((v) => v.mpvValue == raw, orElse: () => auto);
}

/// Values for the `transform` option of the `equalizer` audio filter.
enum EqualizerTransformType {
  /// direct form I
  di,

  /// direct form II
  dii,

  /// transposed direct form I
  tdi,

  /// transposed direct form II
  tdii,

  /// lattice-ladder form
  latt,

  /// state variable filter form
  svf,

  /// zero-delay filter form
  zdf;

  /// Wire-side string consumed by mpv.
  String get mpvValue => switch (this) {
    di => 'di',
    dii => 'dii',
    tdi => 'tdi',
    tdii => 'tdii',
    latt => 'latt',
    svf => 'svf',
    zdf => 'zdf',
  };

  /// Parses a mpv wire string back into a [EqualizerTransformType].
  /// Unknown or empty input falls back to the first member.
  static EqualizerTransformType fromMpv(String? raw) =>
      values.firstWhere((v) => v.mpvValue == raw, orElse: () => di);
}

/// Values for the `width_type` option of the `equalizer` audio filter.
enum EqualizerWidthType {
  /// Hz
  h,

  /// Q-Factor
  q,

  /// octave
  o,

  /// slope
  s,

  /// kHz
  k;

  /// Wire-side string consumed by mpv.
  String get mpvValue => switch (this) {
    h => 'h',
    q => 'q',
    o => 'o',
    s => 's',
    k => 'k',
  };

  /// Parses a mpv wire string back into a [EqualizerWidthType].
  /// Unknown or empty input falls back to the first member.
  static EqualizerWidthType fromMpv(String? raw) =>
      values.firstWhere((v) => v.mpvValue == raw, orElse: () => h);
}

/// Values for the `dumpscale` option of the `firequalizer` audio filter.
enum FirequalizerScale {
  /// linear-freq linear-gain
  linlin,

  /// linear-freq logarithmic-gain
  linlog,

  /// logarithmic-freq linear-gain
  loglin,

  /// logarithmic-freq logarithmic-gain
  loglog;

  /// Wire-side string consumed by mpv.
  String get mpvValue => switch (this) {
    linlin => 'linlin',
    linlog => 'linlog',
    loglin => 'loglin',
    loglog => 'loglog',
  };

  /// Parses a mpv wire string back into a [FirequalizerScale].
  /// Unknown or empty input falls back to the first member.
  static FirequalizerScale fromMpv(String? raw) =>
      values.firstWhere((v) => v.mpvValue == raw, orElse: () => linlin);
}

/// Values for the `wfunc` option of the `firequalizer` audio filter.
enum FirequalizerWfunc {
  /// rectangular window
  rectangular,

  /// hann window
  hann,

  /// hamming window
  hamming,

  /// blackman window
  blackman,

  /// 3-term nuttall window
  nuttall3,

  /// minimum 3-term nuttall window
  mnuttall3,

  /// nuttall window
  nuttall,

  /// blackman-nuttall window
  bnuttall,

  /// blackman-harris window
  bharris,

  /// tukey window
  tukey;

  /// Wire-side string consumed by mpv.
  String get mpvValue => switch (this) {
    rectangular => 'rectangular',
    hann => 'hann',
    hamming => 'hamming',
    blackman => 'blackman',
    nuttall3 => 'nuttall3',
    mnuttall3 => 'mnuttall3',
    nuttall => 'nuttall',
    bnuttall => 'bnuttall',
    bharris => 'bharris',
    tukey => 'tukey',
  };

  /// Parses a mpv wire string back into a [FirequalizerWfunc].
  /// Unknown or empty input falls back to the first member.
  static FirequalizerWfunc fromMpv(String? raw) =>
      values.firstWhere((v) => v.mpvValue == raw, orElse: () => rectangular);
}

/// Values for the `interp` option of the `flanger` audio filter.
enum FlangerItype {
  /// The `linear` option value.
  linear,

  /// The `quadratic` option value.
  quadratic;

  /// Wire-side string consumed by mpv.
  String get mpvValue => switch (this) {
    linear => 'linear',
    quadratic => 'quadratic',
  };

  /// Parses a mpv wire string back into a [FlangerItype].
  /// Unknown or empty input falls back to the first member.
  static FlangerItype fromMpv(String? raw) =>
      values.firstWhere((v) => v.mpvValue == raw, orElse: () => linear);
}

/// Values for the `shape` option of the `flanger` audio filter.
enum FlangerType {
  /// The `triangular` option value.
  triangular,

  /// The `t` option value.
  t,

  /// The `sinusoidal` option value.
  sinusoidal,

  /// The `s` option value.
  s;

  /// Wire-side string consumed by mpv.
  String get mpvValue => switch (this) {
    triangular => 'triangular',
    t => 't',
    sinusoidal => 'sinusoidal',
    s => 's',
  };

  /// Parses a mpv wire string back into a [FlangerType].
  /// Unknown or empty input falls back to the first member.
  static FlangerType fromMpv(String? raw) =>
      values.firstWhere((v) => v.mpvValue == raw, orElse: () => triangular);
}

/// Values for the `middle_source` option of the `haas` audio filter.
enum HaasSource {
  /// The `left` option value.
  left,

  /// The `right` option value.
  right,

  /// L+R
  mid,

  /// L-R
  side;

  /// Wire-side string consumed by mpv.
  String get mpvValue => switch (this) {
    left => 'left',
    right => 'right',
    mid => 'mid',
    side => 'side',
  };

  /// Parses a mpv wire string back into a [HaasSource].
  /// Unknown or empty input falls back to the first member.
  static HaasSource fromMpv(String? raw) =>
      values.firstWhere((v) => v.mpvValue == raw, orElse: () => left);
}

/// Values for the `analyze_mode` option of the `hdcd` audio filter.
enum HdcdAnalyzeMode {
  /// The `off` option value.
  off,

  /// The `lle` option value.
  lle,

  /// The `pe` option value.
  pe,

  /// The `cdt` option value.
  cdt,

  /// The `tgm` option value.
  tgm;

  /// Wire-side string consumed by mpv.
  String get mpvValue => switch (this) {
    off => 'off',
    lle => 'lle',
    pe => 'pe',
    cdt => 'cdt',
    tgm => 'tgm',
  };

  /// Parses a mpv wire string back into a [HdcdAnalyzeMode].
  /// Unknown or empty input falls back to the first member.
  static HdcdAnalyzeMode fromMpv(String? raw) =>
      values.firstWhere((v) => v.mpvValue == raw, orElse: () => off);
}

/// Values for the `bits_per_sample` option of the `hdcd` audio filter.
enum HdcdBitsPerSample {
  /// 16-bit (in s32 or s16)
  n16,

  /// 20-bit (in s32)
  n20,

  /// 24-bit (in s32)
  n24;

  /// Wire-side string consumed by mpv.
  String get mpvValue => switch (this) {
    n16 => '16',
    n20 => '20',
    n24 => '24',
  };

  /// Parses a mpv wire string back into a [HdcdBitsPerSample].
  /// Unknown or empty input falls back to the first member.
  static HdcdBitsPerSample fromMpv(String? raw) =>
      values.firstWhere((v) => v.mpvValue == raw, orElse: () => n16);
}

/// Values for the `precision` option of the `highpass` audio filter.
enum HighpassPrecision {
  /// automatic
  auto,

  /// signed 16-bit
  s16,

  /// signed 32-bit
  s32,

  /// floating-point single
  f32,

  /// floating-point double
  f64;

  /// Wire-side string consumed by mpv.
  String get mpvValue => switch (this) {
    auto => 'auto',
    s16 => 's16',
    s32 => 's32',
    f32 => 'f32',
    f64 => 'f64',
  };

  /// Parses a mpv wire string back into a [HighpassPrecision].
  /// Unknown or empty input falls back to the first member.
  static HighpassPrecision fromMpv(String? raw) =>
      values.firstWhere((v) => v.mpvValue == raw, orElse: () => auto);
}

/// Values for the `transform` option of the `highpass` audio filter.
enum HighpassTransformType {
  /// direct form I
  di,

  /// direct form II
  dii,

  /// transposed direct form I
  tdi,

  /// transposed direct form II
  tdii,

  /// lattice-ladder form
  latt,

  /// state variable filter form
  svf,

  /// zero-delay filter form
  zdf;

  /// Wire-side string consumed by mpv.
  String get mpvValue => switch (this) {
    di => 'di',
    dii => 'dii',
    tdi => 'tdi',
    tdii => 'tdii',
    latt => 'latt',
    svf => 'svf',
    zdf => 'zdf',
  };

  /// Parses a mpv wire string back into a [HighpassTransformType].
  /// Unknown or empty input falls back to the first member.
  static HighpassTransformType fromMpv(String? raw) =>
      values.firstWhere((v) => v.mpvValue == raw, orElse: () => di);
}

/// Values for the `width_type` option of the `highpass` audio filter.
enum HighpassWidthType {
  /// Hz
  h,

  /// Q-Factor
  q,

  /// octave
  o,

  /// slope
  s,

  /// kHz
  k;

  /// Wire-side string consumed by mpv.
  String get mpvValue => switch (this) {
    h => 'h',
    q => 'q',
    o => 'o',
    s => 's',
    k => 'k',
  };

  /// Parses a mpv wire string back into a [HighpassWidthType].
  /// Unknown or empty input falls back to the first member.
  static HighpassWidthType fromMpv(String? raw) =>
      values.firstWhere((v) => v.mpvValue == raw, orElse: () => h);
}

/// Values for the `precision` option of the `highshelf` audio filter.
enum HighshelfPrecision {
  /// automatic
  auto,

  /// signed 16-bit
  s16,

  /// signed 32-bit
  s32,

  /// floating-point single
  f32,

  /// floating-point double
  f64;

  /// Wire-side string consumed by mpv.
  String get mpvValue => switch (this) {
    auto => 'auto',
    s16 => 's16',
    s32 => 's32',
    f32 => 'f32',
    f64 => 'f64',
  };

  /// Parses a mpv wire string back into a [HighshelfPrecision].
  /// Unknown or empty input falls back to the first member.
  static HighshelfPrecision fromMpv(String? raw) =>
      values.firstWhere((v) => v.mpvValue == raw, orElse: () => auto);
}

/// Values for the `transform` option of the `highshelf` audio filter.
enum HighshelfTransformType {
  /// direct form I
  di,

  /// direct form II
  dii,

  /// transposed direct form I
  tdi,

  /// transposed direct form II
  tdii,

  /// lattice-ladder form
  latt,

  /// state variable filter form
  svf,

  /// zero-delay filter form
  zdf;

  /// Wire-side string consumed by mpv.
  String get mpvValue => switch (this) {
    di => 'di',
    dii => 'dii',
    tdi => 'tdi',
    tdii => 'tdii',
    latt => 'latt',
    svf => 'svf',
    zdf => 'zdf',
  };

  /// Parses a mpv wire string back into a [HighshelfTransformType].
  /// Unknown or empty input falls back to the first member.
  static HighshelfTransformType fromMpv(String? raw) =>
      values.firstWhere((v) => v.mpvValue == raw, orElse: () => di);
}

/// Values for the `width_type` option of the `highshelf` audio filter.
enum HighshelfWidthType {
  /// Hz
  h,

  /// Q-Factor
  q,

  /// octave
  o,

  /// slope
  s,

  /// kHz
  k;

  /// Wire-side string consumed by mpv.
  String get mpvValue => switch (this) {
    h => 'h',
    q => 'q',
    o => 'o',
    s => 's',
    k => 'k',
  };

  /// Parses a mpv wire string back into a [HighshelfWidthType].
  /// Unknown or empty input falls back to the first member.
  static HighshelfWidthType fromMpv(String? raw) =>
      values.firstWhere((v) => v.mpvValue == raw, orElse: () => h);
}

/// Values for the `print_format` option of the `loudnorm` audio filter.
enum LoudnormPrintFormat {
  /// The `none` option value.
  none,

  /// The `json` option value.
  json,

  /// The `summary` option value.
  summary;

  /// Wire-side string consumed by mpv.
  String get mpvValue => switch (this) {
    none => 'none',
    json => 'json',
    summary => 'summary',
  };

  /// Parses a mpv wire string back into a [LoudnormPrintFormat].
  /// Unknown or empty input falls back to the first member.
  static LoudnormPrintFormat fromMpv(String? raw) =>
      values.firstWhere((v) => v.mpvValue == raw, orElse: () => none);
}

/// Values for the `precision` option of the `lowpass` audio filter.
enum LowpassPrecision {
  /// automatic
  auto,

  /// signed 16-bit
  s16,

  /// signed 32-bit
  s32,

  /// floating-point single
  f32,

  /// floating-point double
  f64;

  /// Wire-side string consumed by mpv.
  String get mpvValue => switch (this) {
    auto => 'auto',
    s16 => 's16',
    s32 => 's32',
    f32 => 'f32',
    f64 => 'f64',
  };

  /// Parses a mpv wire string back into a [LowpassPrecision].
  /// Unknown or empty input falls back to the first member.
  static LowpassPrecision fromMpv(String? raw) =>
      values.firstWhere((v) => v.mpvValue == raw, orElse: () => auto);
}

/// Values for the `transform` option of the `lowpass` audio filter.
enum LowpassTransformType {
  /// direct form I
  di,

  /// direct form II
  dii,

  /// transposed direct form I
  tdi,

  /// transposed direct form II
  tdii,

  /// lattice-ladder form
  latt,

  /// state variable filter form
  svf,

  /// zero-delay filter form
  zdf;

  /// Wire-side string consumed by mpv.
  String get mpvValue => switch (this) {
    di => 'di',
    dii => 'dii',
    tdi => 'tdi',
    tdii => 'tdii',
    latt => 'latt',
    svf => 'svf',
    zdf => 'zdf',
  };

  /// Parses a mpv wire string back into a [LowpassTransformType].
  /// Unknown or empty input falls back to the first member.
  static LowpassTransformType fromMpv(String? raw) =>
      values.firstWhere((v) => v.mpvValue == raw, orElse: () => di);
}

/// Values for the `width_type` option of the `lowpass` audio filter.
enum LowpassWidthType {
  /// Hz
  h,

  /// Q-Factor
  q,

  /// octave
  o,

  /// slope
  s,

  /// kHz
  k;

  /// Wire-side string consumed by mpv.
  String get mpvValue => switch (this) {
    h => 'h',
    q => 'q',
    o => 'o',
    s => 's',
    k => 'k',
  };

  /// Parses a mpv wire string back into a [LowpassWidthType].
  /// Unknown or empty input falls back to the first member.
  static LowpassWidthType fromMpv(String? raw) =>
      values.firstWhere((v) => v.mpvValue == raw, orElse: () => h);
}

/// Values for the `precision` option of the `lowshelf` audio filter.
enum LowshelfPrecision {
  /// automatic
  auto,

  /// signed 16-bit
  s16,

  /// signed 32-bit
  s32,

  /// floating-point single
  f32,

  /// floating-point double
  f64;

  /// Wire-side string consumed by mpv.
  String get mpvValue => switch (this) {
    auto => 'auto',
    s16 => 's16',
    s32 => 's32',
    f32 => 'f32',
    f64 => 'f64',
  };

  /// Parses a mpv wire string back into a [LowshelfPrecision].
  /// Unknown or empty input falls back to the first member.
  static LowshelfPrecision fromMpv(String? raw) =>
      values.firstWhere((v) => v.mpvValue == raw, orElse: () => auto);
}

/// Values for the `transform` option of the `lowshelf` audio filter.
enum LowshelfTransformType {
  /// direct form I
  di,

  /// direct form II
  dii,

  /// transposed direct form I
  tdi,

  /// transposed direct form II
  tdii,

  /// lattice-ladder form
  latt,

  /// state variable filter form
  svf,

  /// zero-delay filter form
  zdf;

  /// Wire-side string consumed by mpv.
  String get mpvValue => switch (this) {
    di => 'di',
    dii => 'dii',
    tdi => 'tdi',
    tdii => 'tdii',
    latt => 'latt',
    svf => 'svf',
    zdf => 'zdf',
  };

  /// Parses a mpv wire string back into a [LowshelfTransformType].
  /// Unknown or empty input falls back to the first member.
  static LowshelfTransformType fromMpv(String? raw) =>
      values.firstWhere((v) => v.mpvValue == raw, orElse: () => di);
}

/// Values for the `width_type` option of the `lowshelf` audio filter.
enum LowshelfWidthType {
  /// Hz
  h,

  /// Q-Factor
  q,

  /// octave
  o,

  /// slope
  s,

  /// kHz
  k;

  /// Wire-side string consumed by mpv.
  String get mpvValue => switch (this) {
    h => 'h',
    q => 'q',
    o => 'o',
    s => 's',
    k => 'k',
  };

  /// Parses a mpv wire string back into a [LowshelfWidthType].
  /// Unknown or empty input falls back to the first member.
  static LowshelfWidthType fromMpv(String? raw) =>
      values.firstWhere((v) => v.mpvValue == raw, orElse: () => h);
}

/// Values for the `detection` option of the `silenceremove` audio filter.
enum SilenceremoveDetection {
  /// use mean absolute values of samples
  avg,

  /// use root mean squared values of samples
  rms,

  /// use max absolute values of samples
  peak,

  /// use median of absolute values of samples
  median,

  /// use absolute of max peak to min peak difference
  ptp,

  /// use standard deviation from values of samples
  dev;

  /// Wire-side string consumed by mpv.
  String get mpvValue => switch (this) {
    avg => 'avg',
    rms => 'rms',
    peak => 'peak',
    median => 'median',
    ptp => 'ptp',
    dev => 'dev',
  };

  /// Parses a mpv wire string back into a [SilenceremoveDetection].
  /// Unknown or empty input falls back to the first member.
  static SilenceremoveDetection fromMpv(String? raw) =>
      values.firstWhere((v) => v.mpvValue == raw, orElse: () => avg);
}

/// Values for the `start_mode` option of the `silenceremove` audio filter.
enum SilenceremoveMode {
  /// The `any` option value.
  any,

  /// The `all` option value.
  all;

  /// Wire-side string consumed by mpv.
  String get mpvValue => switch (this) {
    any => 'any',
    all => 'all',
  };

  /// Parses a mpv wire string back into a [SilenceremoveMode].
  /// Unknown or empty input falls back to the first member.
  static SilenceremoveMode fromMpv(String? raw) =>
      values.firstWhere((v) => v.mpvValue == raw, orElse: () => any);
}

/// Values for the `timestamp` option of the `silenceremove` audio filter.
enum SilenceremoveTimestamp {
  /// full timestamps rewrite, keep only the start time
  write,

  /// non-dropped frames are left with same timestamp
  copy;

  /// Wire-side string consumed by mpv.
  String get mpvValue => switch (this) {
    write => 'write',
    copy => 'copy',
  };

  /// Parses a mpv wire string back into a [SilenceremoveTimestamp].
  /// Unknown or empty input falls back to the first member.
  static SilenceremoveTimestamp fromMpv(String? raw) =>
      values.firstWhere((v) => v.mpvValue == raw, orElse: () => write);
}

/// Values for the `bmode_in` option of the `stereotools` audio filter.
enum StereotoolsBmode {
  /// The `balance` option value.
  balance,

  /// The `amplitude` option value.
  amplitude,

  /// The `power` option value.
  power;

  /// Wire-side string consumed by mpv.
  String get mpvValue => switch (this) {
    balance => 'balance',
    amplitude => 'amplitude',
    power => 'power',
  };

  /// Parses a mpv wire string back into a [StereotoolsBmode].
  /// Unknown or empty input falls back to the first member.
  static StereotoolsBmode fromMpv(String? raw) =>
      values.firstWhere((v) => v.mpvValue == raw, orElse: () => balance);
}

/// Values for the `mode` option of the `stereotools` audio filter.
enum StereotoolsMode {
  /// The `lr>lr` option value.
  lrToLr,

  /// The `lr>ms` option value.
  lrToMs,

  /// The `ms>lr` option value.
  msToLr,

  /// The `lr>ll` option value.
  lrToLl,

  /// The `lr>rr` option value.
  lrToRr,

  /// The `lr>l+r` option value.
  lrToLPlusR,

  /// The `lr>rl` option value.
  lrToRl,

  /// The `ms>ll` option value.
  msToLl,

  /// The `ms>rr` option value.
  msToRr,

  /// The `ms>rl` option value.
  msToRl,

  /// The `lr>l-r` option value.
  lrToLMinusR;

  /// Wire-side string consumed by mpv.
  String get mpvValue => switch (this) {
    lrToLr => 'lr>lr',
    lrToMs => 'lr>ms',
    msToLr => 'ms>lr',
    lrToLl => 'lr>ll',
    lrToRr => 'lr>rr',
    lrToLPlusR => 'lr>l+r',
    lrToRl => 'lr>rl',
    msToLl => 'ms>ll',
    msToRr => 'ms>rr',
    msToRl => 'ms>rl',
    lrToLMinusR => 'lr>l-r',
  };

  /// Parses a mpv wire string back into a [StereotoolsMode].
  /// Unknown or empty input falls back to the first member.
  static StereotoolsMode fromMpv(String? raw) =>
      values.firstWhere((v) => v.mpvValue == raw, orElse: () => lrToLr);
}

/// Values for the `lfe_mode` option of the `surround` audio filter.
enum SurroundLfeMode {
  /// just add LFE channel
  add,

  /// subtract LFE channel with others
  sub;

  /// Wire-side string consumed by mpv.
  String get mpvValue => switch (this) {
    add => 'add',
    sub => 'sub',
  };

  /// Parses a mpv wire string back into a [SurroundLfeMode].
  /// Unknown or empty input falls back to the first member.
  static SurroundLfeMode fromMpv(String? raw) =>
      values.firstWhere((v) => v.mpvValue == raw, orElse: () => add);
}

/// Values for the `win_func` option of the `surround` audio filter.
enum SurroundWinFunc {
  /// Rectangular
  rect,

  /// Bartlett
  bartlett,

  /// Hann
  hann,

  /// Hanning
  hanning,

  /// Hamming
  hamming,

  /// Blackman
  blackman,

  /// Welch
  welch,

  /// Flat-top
  flattop,

  /// Blackman-Harris
  bharris,

  /// Blackman-Nuttall
  bnuttall,

  /// Bartlett-Hann
  bhann,

  /// Sine
  sine,

  /// Nuttall
  nuttall,

  /// Lanczos
  lanczos,

  /// Gauss
  gauss,

  /// Tukey
  tukey,

  /// Dolph-Chebyshev
  dolph,

  /// Cauchy
  cauchy,

  /// Parzen
  parzen,

  /// Poisson
  poisson,

  /// Bohman
  bohman,

  /// Kaiser
  kaiser;

  /// Wire-side string consumed by mpv.
  String get mpvValue => switch (this) {
    rect => 'rect',
    bartlett => 'bartlett',
    hann => 'hann',
    hanning => 'hanning',
    hamming => 'hamming',
    blackman => 'blackman',
    welch => 'welch',
    flattop => 'flattop',
    bharris => 'bharris',
    bnuttall => 'bnuttall',
    bhann => 'bhann',
    sine => 'sine',
    nuttall => 'nuttall',
    lanczos => 'lanczos',
    gauss => 'gauss',
    tukey => 'tukey',
    dolph => 'dolph',
    cauchy => 'cauchy',
    parzen => 'parzen',
    poisson => 'poisson',
    bohman => 'bohman',
    kaiser => 'kaiser',
  };

  /// Parses a mpv wire string back into a [SurroundWinFunc].
  /// Unknown or empty input falls back to the first member.
  static SurroundWinFunc fromMpv(String? raw) =>
      values.firstWhere((v) => v.mpvValue == raw, orElse: () => rect);
}

/// Values for the `precision` option of the `tiltshelf` audio filter.
enum TiltshelfPrecision {
  /// automatic
  auto,

  /// signed 16-bit
  s16,

  /// signed 32-bit
  s32,

  /// floating-point single
  f32,

  /// floating-point double
  f64;

  /// Wire-side string consumed by mpv.
  String get mpvValue => switch (this) {
    auto => 'auto',
    s16 => 's16',
    s32 => 's32',
    f32 => 'f32',
    f64 => 'f64',
  };

  /// Parses a mpv wire string back into a [TiltshelfPrecision].
  /// Unknown or empty input falls back to the first member.
  static TiltshelfPrecision fromMpv(String? raw) =>
      values.firstWhere((v) => v.mpvValue == raw, orElse: () => auto);
}

/// Values for the `transform` option of the `tiltshelf` audio filter.
enum TiltshelfTransformType {
  /// direct form I
  di,

  /// direct form II
  dii,

  /// transposed direct form I
  tdi,

  /// transposed direct form II
  tdii,

  /// lattice-ladder form
  latt,

  /// state variable filter form
  svf,

  /// zero-delay filter form
  zdf;

  /// Wire-side string consumed by mpv.
  String get mpvValue => switch (this) {
    di => 'di',
    dii => 'dii',
    tdi => 'tdi',
    tdii => 'tdii',
    latt => 'latt',
    svf => 'svf',
    zdf => 'zdf',
  };

  /// Parses a mpv wire string back into a [TiltshelfTransformType].
  /// Unknown or empty input falls back to the first member.
  static TiltshelfTransformType fromMpv(String? raw) =>
      values.firstWhere((v) => v.mpvValue == raw, orElse: () => di);
}

/// Values for the `width_type` option of the `tiltshelf` audio filter.
enum TiltshelfWidthType {
  /// Hz
  h,

  /// Q-Factor
  q,

  /// octave
  o,

  /// slope
  s,

  /// kHz
  k;

  /// Wire-side string consumed by mpv.
  String get mpvValue => switch (this) {
    h => 'h',
    q => 'q',
    o => 'o',
    s => 's',
    k => 'k',
  };

  /// Parses a mpv wire string back into a [TiltshelfWidthType].
  /// Unknown or empty input falls back to the first member.
  static TiltshelfWidthType fromMpv(String? raw) =>
      values.firstWhere((v) => v.mpvValue == raw, orElse: () => h);
}

/// Values for the `precision` option of the `treble` audio filter.
enum TreblePrecision {
  /// automatic
  auto,

  /// signed 16-bit
  s16,

  /// signed 32-bit
  s32,

  /// floating-point single
  f32,

  /// floating-point double
  f64;

  /// Wire-side string consumed by mpv.
  String get mpvValue => switch (this) {
    auto => 'auto',
    s16 => 's16',
    s32 => 's32',
    f32 => 'f32',
    f64 => 'f64',
  };

  /// Parses a mpv wire string back into a [TreblePrecision].
  /// Unknown or empty input falls back to the first member.
  static TreblePrecision fromMpv(String? raw) =>
      values.firstWhere((v) => v.mpvValue == raw, orElse: () => auto);
}

/// Values for the `transform` option of the `treble` audio filter.
enum TrebleTransformType {
  /// direct form I
  di,

  /// direct form II
  dii,

  /// transposed direct form I
  tdi,

  /// transposed direct form II
  tdii,

  /// lattice-ladder form
  latt,

  /// state variable filter form
  svf,

  /// zero-delay filter form
  zdf;

  /// Wire-side string consumed by mpv.
  String get mpvValue => switch (this) {
    di => 'di',
    dii => 'dii',
    tdi => 'tdi',
    tdii => 'tdii',
    latt => 'latt',
    svf => 'svf',
    zdf => 'zdf',
  };

  /// Parses a mpv wire string back into a [TrebleTransformType].
  /// Unknown or empty input falls back to the first member.
  static TrebleTransformType fromMpv(String? raw) =>
      values.firstWhere((v) => v.mpvValue == raw, orElse: () => di);
}

/// Values for the `width_type` option of the `treble` audio filter.
enum TrebleWidthType {
  /// Hz
  h,

  /// Q-Factor
  q,

  /// octave
  o,

  /// slope
  s,

  /// kHz
  k;

  /// Wire-side string consumed by mpv.
  String get mpvValue => switch (this) {
    h => 'h',
    q => 'q',
    o => 'o',
    s => 's',
    k => 'k',
  };

  /// Parses a mpv wire string back into a [TrebleWidthType].
  /// Unknown or empty input falls back to the first member.
  static TrebleWidthType fromMpv(String? raw) =>
      values.firstWhere((v) => v.mpvValue == raw, orElse: () => h);
}

/// Identifies one of the typed audio filters: one value per
/// `XxxEffect` class, i.e. per filter compiled into the bundled
/// libmpv. Use it as a typed identifier in APIs that pick a filter,
/// e.g. `player.stream.tap(AudioFilter.equalizer, side: TapSide.post)`.
enum AudioFilter {
  /// The `acompressor` audio filter.
  acompressor,

  /// The `acontrast` audio filter.
  acontrast,

  /// The `acrusher` audio filter.
  acrusher,

  /// The `adeclick` audio filter.
  adeclick,

  /// The `adeclip` audio filter.
  adeclip,

  /// The `adecorrelate` audio filter.
  adecorrelate,

  /// The `adelay` audio filter.
  adelay,

  /// The `adenorm` audio filter.
  adenorm,

  /// The `aderivative` audio filter.
  aderivative,

  /// The `adrc` audio filter.
  adrc,

  /// The `adynamicequalizer` audio filter.
  adynamicequalizer,

  /// The `adynamicsmooth` audio filter.
  adynamicsmooth,

  /// The `aecho` audio filter.
  aecho,

  /// The `aemphasis` audio filter.
  aemphasis,

  /// The `aeval` audio filter.
  aeval,

  /// The `aexciter` audio filter.
  aexciter,

  /// The `afade` audio filter.
  afade,

  /// The `afftdn` audio filter.
  afftdn,

  /// The `afftfilt` audio filter.
  afftfilt,

  /// The `aformat` audio filter.
  aformat,

  /// The `afreqshift` audio filter.
  afreqshift,

  /// The `afwtdn` audio filter.
  afwtdn,

  /// The `agate` audio filter.
  agate,

  /// The `aiir` audio filter.
  aiir,

  /// The `aintegral` audio filter.
  aintegral,

  /// The `alimiter` audio filter.
  alimiter,

  /// The `allpass` audio filter.
  allpass,

  /// The `anequalizer` audio filter.
  anequalizer,

  /// The `anlmdn` audio filter.
  anlmdn,

  /// The `apad` audio filter.
  apad,

  /// The `aphaser` audio filter.
  aphaser,

  /// The `aphaseshift` audio filter.
  aphaseshift,

  /// The `apsyclip` audio filter.
  apsyclip,

  /// The `apulsator` audio filter.
  apulsator,

  /// The `aresample` audio filter.
  aresample,

  /// The `arnndn` audio filter.
  arnndn,

  /// The `asetrate` audio filter.
  asetrate,

  /// The `asoftclip` audio filter.
  asoftclip,

  /// The `asubboost` audio filter.
  asubboost,

  /// The `asubcut` audio filter.
  asubcut,

  /// The `asupercut` audio filter.
  asupercut,

  /// The `asuperpass` audio filter.
  asuperpass,

  /// The `asuperstop` audio filter.
  asuperstop,

  /// The `atempo` audio filter.
  atempo,

  /// The `atilt` audio filter.
  atilt,

  /// The `bandpass` audio filter.
  bandpass,

  /// The `bandreject` audio filter.
  bandreject,

  /// The `bass` audio filter.
  bass,

  /// The `biquad` audio filter.
  biquad,

  /// The `channelmap` audio filter.
  channelmap,

  /// The `chorus` audio filter.
  chorus,

  /// The `compand` audio filter.
  compand,

  /// The `compensationdelay` audio filter.
  compensationdelay,

  /// The `crossfeed` audio filter.
  crossfeed,

  /// The `crystalizer` audio filter.
  crystalizer,

  /// The `dcshift` audio filter.
  dcshift,

  /// The `deesser` audio filter.
  deesser,

  /// The `dialoguenhance` audio filter.
  dialoguenhance,

  /// The `drmeter` audio filter.
  drmeter,

  /// The `dynaudnorm` audio filter.
  dynaudnorm,

  /// The `earwax` audio filter.
  earwax,

  /// The `ebur128` audio filter.
  ebur128,

  /// The `equalizer` audio filter.
  equalizer,

  /// The `extrastereo` audio filter.
  extrastereo,

  /// The `firequalizer` audio filter.
  firequalizer,

  /// The `flanger` audio filter.
  flanger,

  /// The `haas` audio filter.
  haas,

  /// The `hdcd` audio filter.
  hdcd,

  /// The `highpass` audio filter.
  highpass,

  /// The `highshelf` audio filter.
  highshelf,

  /// The `loudnorm` audio filter.
  loudnorm,

  /// The `lowpass` audio filter.
  lowpass,

  /// The `lowshelf` audio filter.
  lowshelf,

  /// The `mcompand` audio filter.
  mcompand,

  /// The `pan` audio filter.
  pan,

  /// The `silenceremove` audio filter.
  silenceremove,

  /// The `speechnorm` audio filter.
  speechnorm,

  /// The `stereotools` audio filter.
  stereotools,

  /// The `stereowiden` audio filter.
  stereowiden,

  /// The `superequalizer` audio filter.
  superequalizer,

  /// The `surround` audio filter.
  surround,

  /// The `tiltshelf` audio filter.
  tiltshelf,

  /// The `treble` audio filter.
  treble,

  /// The `tremolo` audio filter.
  tremolo,

  /// The `vibrato` audio filter.
  vibrato,

  /// The `virtualbass` audio filter.
  virtualbass;

  /// mpv filter-type name. Coincides with the enum value
  /// [name] for every entry on the current whitelist; the
  /// getter exists so consumers don't depend on that
  /// coincidence (a future filter colliding with a Dart
  /// reserved word would gain a trailing `_` on its enum
  /// value, which this getter would strip).
  String get filterName {
    final n = name;
    return n.endsWith('_') ? n.substring(0, n.length - 1) : n;
  }
}
