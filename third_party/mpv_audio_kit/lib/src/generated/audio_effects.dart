// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license
// that can be found in the LICENSE file.
//
// AUTO-GENERATED — do not edit by hand.
// ignore_for_file: constant_identifier_names, camel_case_types, non_constant_identifier_names

/// Values for the `detection` option of the `acompressor` audio filter.
enum AcompressorDetection {
  /// The `peak` option value.
  peak,

  /// The `rms` option value.
  rms,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case AcompressorDetection.peak:
        return 'peak';
      case AcompressorDetection.rms:
        return 'rms';
    }
  }

  /// Parses a mpv wire string back into a [AcompressorDetection].
  /// Unknown / empty input falls back to the first member.
  static AcompressorDetection fromMpv(String? raw) {
    switch (raw) {
      case 'peak':
        return AcompressorDetection.peak;
      case 'rms':
        return AcompressorDetection.rms;
      default:
        return AcompressorDetection.peak;
    }
  }
}

/// Values for the `link` option of the `acompressor` audio filter.
enum AcompressorLink {
  /// The `average` option value.
  average,

  /// The `maximum` option value.
  maximum,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case AcompressorLink.average:
        return 'average';
      case AcompressorLink.maximum:
        return 'maximum';
    }
  }

  /// Parses a mpv wire string back into a [AcompressorLink].
  /// Unknown / empty input falls back to the first member.
  static AcompressorLink fromMpv(String? raw) {
    switch (raw) {
      case 'average':
        return AcompressorLink.average;
      case 'maximum':
        return AcompressorLink.maximum;
      default:
        return AcompressorLink.average;
    }
  }
}

/// Values for the `mode` option of the `acompressor` audio filter.
enum AcompressorMode {
  /// The `downward` option value.
  downward,

  /// The `upward` option value.
  upward,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case AcompressorMode.downward:
        return 'downward';
      case AcompressorMode.upward:
        return 'upward';
    }
  }

  /// Parses a mpv wire string back into a [AcompressorMode].
  /// Unknown / empty input falls back to the first member.
  static AcompressorMode fromMpv(String? raw) {
    switch (raw) {
      case 'downward':
        return AcompressorMode.downward;
      case 'upward':
        return AcompressorMode.upward;
      default:
        return AcompressorMode.downward;
    }
  }
}

/// Values for the `mode` option of the `acrusher` audio filter.
enum AcrusherMode {
  /// linear
  lin,

  /// logarithmic
  log,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case AcrusherMode.lin:
        return 'lin';
      case AcrusherMode.log:
        return 'log';
    }
  }

  /// Parses a mpv wire string back into a [AcrusherMode].
  /// Unknown / empty input falls back to the first member.
  static AcrusherMode fromMpv(String? raw) {
    switch (raw) {
      case 'lin':
        return AcrusherMode.lin;
      case 'log':
        return AcrusherMode.log;
      default:
        return AcrusherMode.lin;
    }
  }
}

/// Values for the `m` option of the `adeclick` audio filter.
enum AdeclickM {
  /// overlap-add
  add,

  /// overlap-add
  a,

  /// overlap-save
  save,

  /// overlap-save
  s,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case AdeclickM.add:
        return 'add';
      case AdeclickM.a:
        return 'a';
      case AdeclickM.save:
        return 'save';
      case AdeclickM.s:
        return 's';
    }
  }

  /// Parses a mpv wire string back into a [AdeclickM].
  /// Unknown / empty input falls back to the first member.
  static AdeclickM fromMpv(String? raw) {
    switch (raw) {
      case 'add':
        return AdeclickM.add;
      case 'a':
        return AdeclickM.a;
      case 'save':
        return AdeclickM.save;
      case 's':
        return AdeclickM.s;
      default:
        return AdeclickM.add;
    }
  }
}

/// Values for the `m` option of the `adeclip` audio filter.
enum AdeclipM {
  /// overlap-add
  add,

  /// overlap-add
  a,

  /// overlap-save
  save,

  /// overlap-save
  s,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case AdeclipM.add:
        return 'add';
      case AdeclipM.a:
        return 'a';
      case AdeclipM.save:
        return 'save';
      case AdeclipM.s:
        return 's';
    }
  }

  /// Parses a mpv wire string back into a [AdeclipM].
  /// Unknown / empty input falls back to the first member.
  static AdeclipM fromMpv(String? raw) {
    switch (raw) {
      case 'add':
        return AdeclipM.add;
      case 'a':
        return AdeclipM.a;
      case 'save':
        return AdeclipM.save;
      case 's':
        return AdeclipM.s;
      default:
        return AdeclipM.add;
    }
  }
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
  pulse,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case AdenormType.dc:
        return 'dc';
      case AdenormType.ac:
        return 'ac';
      case AdenormType.square:
        return 'square';
      case AdenormType.pulse:
        return 'pulse';
    }
  }

  /// Parses a mpv wire string back into a [AdenormType].
  /// Unknown / empty input falls back to the first member.
  static AdenormType fromMpv(String? raw) {
    switch (raw) {
      case 'dc':
        return AdenormType.dc;
      case 'ac':
        return AdenormType.ac;
      case 'square':
        return AdenormType.square;
      case 'pulse':
        return AdenormType.pulse;
      default:
        return AdenormType.dc;
    }
  }
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
  adaptive,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case AdynamicequalizerAuto.disabled:
        return 'disabled';
      case AdynamicequalizerAuto.off:
        return 'off';
      case AdynamicequalizerAuto.on_:
        return 'on';
      case AdynamicequalizerAuto.adaptive:
        return 'adaptive';
    }
  }

  /// Parses a mpv wire string back into a [AdynamicequalizerAuto].
  /// Unknown / empty input falls back to the first member.
  static AdynamicequalizerAuto fromMpv(String? raw) {
    switch (raw) {
      case 'disabled':
        return AdynamicequalizerAuto.disabled;
      case 'off':
        return AdynamicequalizerAuto.off;
      case 'on':
        return AdynamicequalizerAuto.on_;
      case 'adaptive':
        return AdynamicequalizerAuto.adaptive;
      default:
        return AdynamicequalizerAuto.disabled;
    }
  }
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
  peak,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case AdynamicequalizerDftype.bandpass:
        return 'bandpass';
      case AdynamicequalizerDftype.lowpass:
        return 'lowpass';
      case AdynamicequalizerDftype.highpass:
        return 'highpass';
      case AdynamicequalizerDftype.peak:
        return 'peak';
    }
  }

  /// Parses a mpv wire string back into a [AdynamicequalizerDftype].
  /// Unknown / empty input falls back to the first member.
  static AdynamicequalizerDftype fromMpv(String? raw) {
    switch (raw) {
      case 'bandpass':
        return AdynamicequalizerDftype.bandpass;
      case 'lowpass':
        return AdynamicequalizerDftype.lowpass;
      case 'highpass':
        return AdynamicequalizerDftype.highpass;
      case 'peak':
        return AdynamicequalizerDftype.peak;
      default:
        return AdynamicequalizerDftype.bandpass;
    }
  }
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
  boostabove,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case AdynamicequalizerMode.listen:
        return 'listen';
      case AdynamicequalizerMode.cutbelow:
        return 'cutbelow';
      case AdynamicequalizerMode.cutabove:
        return 'cutabove';
      case AdynamicequalizerMode.boostbelow:
        return 'boostbelow';
      case AdynamicequalizerMode.boostabove:
        return 'boostabove';
    }
  }

  /// Parses a mpv wire string back into a [AdynamicequalizerMode].
  /// Unknown / empty input falls back to the first member.
  static AdynamicequalizerMode fromMpv(String? raw) {
    switch (raw) {
      case 'listen':
        return AdynamicequalizerMode.listen;
      case 'cutbelow':
        return AdynamicequalizerMode.cutbelow;
      case 'cutabove':
        return AdynamicequalizerMode.cutabove;
      case 'boostbelow':
        return AdynamicequalizerMode.boostbelow;
      case 'boostabove':
        return AdynamicequalizerMode.boostabove;
      default:
        return AdynamicequalizerMode.listen;
    }
  }
}

/// Values for the `precision` option of the `adynamicequalizer` audio filter.
enum AdynamicequalizerPrecision {
  /// set auto processing precision
  auto,

  /// set single-floating point processing precision
  float,

  /// set double-floating point processing precision
  double_,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case AdynamicequalizerPrecision.auto:
        return 'auto';
      case AdynamicequalizerPrecision.float:
        return 'float';
      case AdynamicequalizerPrecision.double_:
        return 'double';
    }
  }

  /// Parses a mpv wire string back into a [AdynamicequalizerPrecision].
  /// Unknown / empty input falls back to the first member.
  static AdynamicequalizerPrecision fromMpv(String? raw) {
    switch (raw) {
      case 'auto':
        return AdynamicequalizerPrecision.auto;
      case 'float':
        return AdynamicequalizerPrecision.float;
      case 'double':
        return AdynamicequalizerPrecision.double_;
      default:
        return AdynamicequalizerPrecision.auto;
    }
  }
}

/// Values for the `tftype` option of the `adynamicequalizer` audio filter.
enum AdynamicequalizerTftype {
  /// The `bell` option value.
  bell,

  /// The `lowshelf` option value.
  lowshelf,

  /// The `highshelf` option value.
  highshelf,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case AdynamicequalizerTftype.bell:
        return 'bell';
      case AdynamicequalizerTftype.lowshelf:
        return 'lowshelf';
      case AdynamicequalizerTftype.highshelf:
        return 'highshelf';
    }
  }

  /// Parses a mpv wire string back into a [AdynamicequalizerTftype].
  /// Unknown / empty input falls back to the first member.
  static AdynamicequalizerTftype fromMpv(String? raw) {
    switch (raw) {
      case 'bell':
        return AdynamicequalizerTftype.bell;
      case 'lowshelf':
        return AdynamicequalizerTftype.lowshelf;
      case 'highshelf':
        return AdynamicequalizerTftype.highshelf;
      default:
        return AdynamicequalizerTftype.bell;
    }
  }
}

/// Values for the `mode` option of the `aemphasis` audio filter.
enum AemphasisMode {
  /// The `reproduction` option value.
  reproduction,

  /// The `production` option value.
  production,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case AemphasisMode.reproduction:
        return 'reproduction';
      case AemphasisMode.production:
        return 'production';
    }
  }

  /// Parses a mpv wire string back into a [AemphasisMode].
  /// Unknown / empty input falls back to the first member.
  static AemphasisMode fromMpv(String? raw) {
    switch (raw) {
      case 'reproduction':
        return AemphasisMode.reproduction;
      case 'production':
        return AemphasisMode.production;
      default:
        return AemphasisMode.reproduction;
    }
  }
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
  n75kf,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case AemphasisType.col:
        return 'col';
      case AemphasisType.emi:
        return 'emi';
      case AemphasisType.bsi:
        return 'bsi';
      case AemphasisType.riaa:
        return 'riaa';
      case AemphasisType.cd:
        return 'cd';
      case AemphasisType.n50fm:
        return '50fm';
      case AemphasisType.n75fm:
        return '75fm';
      case AemphasisType.n50kf:
        return '50kf';
      case AemphasisType.n75kf:
        return '75kf';
    }
  }

  /// Parses a mpv wire string back into a [AemphasisType].
  /// Unknown / empty input falls back to the first member.
  static AemphasisType fromMpv(String? raw) {
    switch (raw) {
      case 'col':
        return AemphasisType.col;
      case 'emi':
        return AemphasisType.emi;
      case 'bsi':
        return AemphasisType.bsi;
      case 'riaa':
        return AemphasisType.riaa;
      case 'cd':
        return AemphasisType.cd;
      case '50fm':
        return AemphasisType.n50fm;
      case '75fm':
        return AemphasisType.n75fm;
      case '50kf':
        return AemphasisType.n50kf;
      case '75kf':
        return AemphasisType.n75kf;
      default:
        return AemphasisType.col;
    }
  }
}

/// Values for the `c` option of the `afade` audio filter.
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
  hsin2,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case AfadeCurve.nofade:
        return 'nofade';
      case AfadeCurve.tri:
        return 'tri';
      case AfadeCurve.qsin:
        return 'qsin';
      case AfadeCurve.esin:
        return 'esin';
      case AfadeCurve.hsin:
        return 'hsin';
      case AfadeCurve.log:
        return 'log';
      case AfadeCurve.ipar:
        return 'ipar';
      case AfadeCurve.qua:
        return 'qua';
      case AfadeCurve.cub:
        return 'cub';
      case AfadeCurve.squ:
        return 'squ';
      case AfadeCurve.cbr:
        return 'cbr';
      case AfadeCurve.par:
        return 'par';
      case AfadeCurve.exp:
        return 'exp';
      case AfadeCurve.iqsin:
        return 'iqsin';
      case AfadeCurve.ihsin:
        return 'ihsin';
      case AfadeCurve.dese:
        return 'dese';
      case AfadeCurve.desi:
        return 'desi';
      case AfadeCurve.losi:
        return 'losi';
      case AfadeCurve.sinc:
        return 'sinc';
      case AfadeCurve.isinc:
        return 'isinc';
      case AfadeCurve.quat:
        return 'quat';
      case AfadeCurve.quatr:
        return 'quatr';
      case AfadeCurve.qsin2:
        return 'qsin2';
      case AfadeCurve.hsin2:
        return 'hsin2';
    }
  }

  /// Parses a mpv wire string back into a [AfadeCurve].
  /// Unknown / empty input falls back to the first member.
  static AfadeCurve fromMpv(String? raw) {
    switch (raw) {
      case 'nofade':
        return AfadeCurve.nofade;
      case 'tri':
        return AfadeCurve.tri;
      case 'qsin':
        return AfadeCurve.qsin;
      case 'esin':
        return AfadeCurve.esin;
      case 'hsin':
        return AfadeCurve.hsin;
      case 'log':
        return AfadeCurve.log;
      case 'ipar':
        return AfadeCurve.ipar;
      case 'qua':
        return AfadeCurve.qua;
      case 'cub':
        return AfadeCurve.cub;
      case 'squ':
        return AfadeCurve.squ;
      case 'cbr':
        return AfadeCurve.cbr;
      case 'par':
        return AfadeCurve.par;
      case 'exp':
        return AfadeCurve.exp;
      case 'iqsin':
        return AfadeCurve.iqsin;
      case 'ihsin':
        return AfadeCurve.ihsin;
      case 'dese':
        return AfadeCurve.dese;
      case 'desi':
        return AfadeCurve.desi;
      case 'losi':
        return AfadeCurve.losi;
      case 'sinc':
        return AfadeCurve.sinc;
      case 'isinc':
        return AfadeCurve.isinc;
      case 'quat':
        return AfadeCurve.quat;
      case 'quatr':
        return AfadeCurve.quatr;
      case 'qsin2':
        return AfadeCurve.qsin2;
      case 'hsin2':
        return AfadeCurve.hsin2;
      default:
        return AfadeCurve.nofade;
    }
  }
}

/// Values for the `t` option of the `afade` audio filter.
enum AfadeType {
  /// fade-in
  in_,

  /// fade-out
  out,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case AfadeType.in_:
        return 'in';
      case AfadeType.out:
        return 'out';
    }
  }

  /// Parses a mpv wire string back into a [AfadeType].
  /// Unknown / empty input falls back to the first member.
  static AfadeType fromMpv(String? raw) {
    switch (raw) {
      case 'in':
        return AfadeType.in_;
      case 'out':
        return AfadeType.out;
      default:
        return AfadeType.in_;
    }
  }
}

/// Values for the `nl` option of the `afftdn` audio filter.
enum AfftdnLink {
  /// none
  none,

  /// min
  min,

  /// max
  max,

  /// average
  average,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case AfftdnLink.none:
        return 'none';
      case AfftdnLink.min:
        return 'min';
      case AfftdnLink.max:
        return 'max';
      case AfftdnLink.average:
        return 'average';
    }
  }

  /// Parses a mpv wire string back into a [AfftdnLink].
  /// Unknown / empty input falls back to the first member.
  static AfftdnLink fromMpv(String? raw) {
    switch (raw) {
      case 'none':
        return AfftdnLink.none;
      case 'min':
        return AfftdnLink.min;
      case 'max':
        return AfftdnLink.max;
      case 'average':
        return AfftdnLink.average;
      default:
        return AfftdnLink.none;
    }
  }
}

/// Values for the `om` option of the `afftdn` audio filter.
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
  n,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case AfftdnMode.input:
        return 'input';
      case AfftdnMode.i:
        return 'i';
      case AfftdnMode.output:
        return 'output';
      case AfftdnMode.o:
        return 'o';
      case AfftdnMode.noise:
        return 'noise';
      case AfftdnMode.n:
        return 'n';
    }
  }

  /// Parses a mpv wire string back into a [AfftdnMode].
  /// Unknown / empty input falls back to the first member.
  static AfftdnMode fromMpv(String? raw) {
    switch (raw) {
      case 'input':
        return AfftdnMode.input;
      case 'i':
        return AfftdnMode.i;
      case 'output':
        return AfftdnMode.output;
      case 'o':
        return AfftdnMode.o;
      case 'noise':
        return AfftdnMode.noise;
      case 'n':
        return AfftdnMode.n;
      default:
        return AfftdnMode.input;
    }
  }
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
  end,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case AfftdnSample.none:
        return 'none';
      case AfftdnSample.start:
        return 'start';
      case AfftdnSample.begin:
        return 'begin';
      case AfftdnSample.stop:
        return 'stop';
      case AfftdnSample.end:
        return 'end';
    }
  }

  /// Parses a mpv wire string back into a [AfftdnSample].
  /// Unknown / empty input falls back to the first member.
  static AfftdnSample fromMpv(String? raw) {
    switch (raw) {
      case 'none':
        return AfftdnSample.none;
      case 'start':
        return AfftdnSample.start;
      case 'begin':
        return AfftdnSample.begin;
      case 'stop':
        return AfftdnSample.stop;
      case 'end':
        return AfftdnSample.end;
      default:
        return AfftdnSample.none;
    }
  }
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
  c,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case AfftdnType.white:
        return 'white';
      case AfftdnType.w:
        return 'w';
      case AfftdnType.vinyl:
        return 'vinyl';
      case AfftdnType.v:
        return 'v';
      case AfftdnType.shellac:
        return 'shellac';
      case AfftdnType.s:
        return 's';
      case AfftdnType.custom:
        return 'custom';
      case AfftdnType.c:
        return 'c';
    }
  }

  /// Parses a mpv wire string back into a [AfftdnType].
  /// Unknown / empty input falls back to the first member.
  static AfftdnType fromMpv(String? raw) {
    switch (raw) {
      case 'white':
        return AfftdnType.white;
      case 'w':
        return AfftdnType.w;
      case 'vinyl':
        return AfftdnType.vinyl;
      case 'v':
        return AfftdnType.v;
      case 'shellac':
        return AfftdnType.shellac;
      case 's':
        return AfftdnType.s;
      case 'custom':
        return AfftdnType.custom;
      case 'c':
        return AfftdnType.c;
      default:
        return AfftdnType.white;
    }
  }
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
  kaiser,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case AfftfiltWinFunc.rect:
        return 'rect';
      case AfftfiltWinFunc.bartlett:
        return 'bartlett';
      case AfftfiltWinFunc.hann:
        return 'hann';
      case AfftfiltWinFunc.hanning:
        return 'hanning';
      case AfftfiltWinFunc.hamming:
        return 'hamming';
      case AfftfiltWinFunc.blackman:
        return 'blackman';
      case AfftfiltWinFunc.welch:
        return 'welch';
      case AfftfiltWinFunc.flattop:
        return 'flattop';
      case AfftfiltWinFunc.bharris:
        return 'bharris';
      case AfftfiltWinFunc.bnuttall:
        return 'bnuttall';
      case AfftfiltWinFunc.bhann:
        return 'bhann';
      case AfftfiltWinFunc.sine:
        return 'sine';
      case AfftfiltWinFunc.nuttall:
        return 'nuttall';
      case AfftfiltWinFunc.lanczos:
        return 'lanczos';
      case AfftfiltWinFunc.gauss:
        return 'gauss';
      case AfftfiltWinFunc.tukey:
        return 'tukey';
      case AfftfiltWinFunc.dolph:
        return 'dolph';
      case AfftfiltWinFunc.cauchy:
        return 'cauchy';
      case AfftfiltWinFunc.parzen:
        return 'parzen';
      case AfftfiltWinFunc.poisson:
        return 'poisson';
      case AfftfiltWinFunc.bohman:
        return 'bohman';
      case AfftfiltWinFunc.kaiser:
        return 'kaiser';
    }
  }

  /// Parses a mpv wire string back into a [AfftfiltWinFunc].
  /// Unknown / empty input falls back to the first member.
  static AfftfiltWinFunc fromMpv(String? raw) {
    switch (raw) {
      case 'rect':
        return AfftfiltWinFunc.rect;
      case 'bartlett':
        return AfftfiltWinFunc.bartlett;
      case 'hann':
        return AfftfiltWinFunc.hann;
      case 'hanning':
        return AfftfiltWinFunc.hanning;
      case 'hamming':
        return AfftfiltWinFunc.hamming;
      case 'blackman':
        return AfftfiltWinFunc.blackman;
      case 'welch':
        return AfftfiltWinFunc.welch;
      case 'flattop':
        return AfftfiltWinFunc.flattop;
      case 'bharris':
        return AfftfiltWinFunc.bharris;
      case 'bnuttall':
        return AfftfiltWinFunc.bnuttall;
      case 'bhann':
        return AfftfiltWinFunc.bhann;
      case 'sine':
        return AfftfiltWinFunc.sine;
      case 'nuttall':
        return AfftfiltWinFunc.nuttall;
      case 'lanczos':
        return AfftfiltWinFunc.lanczos;
      case 'gauss':
        return AfftfiltWinFunc.gauss;
      case 'tukey':
        return AfftfiltWinFunc.tukey;
      case 'dolph':
        return AfftfiltWinFunc.dolph;
      case 'cauchy':
        return AfftfiltWinFunc.cauchy;
      case 'parzen':
        return AfftfiltWinFunc.parzen;
      case 'poisson':
        return AfftfiltWinFunc.poisson;
      case 'bohman':
        return AfftfiltWinFunc.bohman;
      case 'kaiser':
        return AfftfiltWinFunc.kaiser;
      default:
        return AfftfiltWinFunc.rect;
    }
  }
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
  bl3,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case AfwtdnWavet.sym2:
        return 'sym2';
      case AfwtdnWavet.sym4:
        return 'sym4';
      case AfwtdnWavet.rbior68:
        return 'rbior68';
      case AfwtdnWavet.deb10:
        return 'deb10';
      case AfwtdnWavet.sym10:
        return 'sym10';
      case AfwtdnWavet.coif5:
        return 'coif5';
      case AfwtdnWavet.bl3:
        return 'bl3';
    }
  }

  /// Parses a mpv wire string back into a [AfwtdnWavet].
  /// Unknown / empty input falls back to the first member.
  static AfwtdnWavet fromMpv(String? raw) {
    switch (raw) {
      case 'sym2':
        return AfwtdnWavet.sym2;
      case 'sym4':
        return AfwtdnWavet.sym4;
      case 'rbior68':
        return AfwtdnWavet.rbior68;
      case 'deb10':
        return AfwtdnWavet.deb10;
      case 'sym10':
        return AfwtdnWavet.sym10;
      case 'coif5':
        return AfwtdnWavet.coif5;
      case 'bl3':
        return AfwtdnWavet.bl3;
      default:
        return AfwtdnWavet.sym2;
    }
  }
}

/// Values for the `detection` option of the `agate` audio filter.
enum AgateDetection {
  /// The `peak` option value.
  peak,

  /// The `rms` option value.
  rms,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case AgateDetection.peak:
        return 'peak';
      case AgateDetection.rms:
        return 'rms';
    }
  }

  /// Parses a mpv wire string back into a [AgateDetection].
  /// Unknown / empty input falls back to the first member.
  static AgateDetection fromMpv(String? raw) {
    switch (raw) {
      case 'peak':
        return AgateDetection.peak;
      case 'rms':
        return AgateDetection.rms;
      default:
        return AgateDetection.peak;
    }
  }
}

/// Values for the `link` option of the `agate` audio filter.
enum AgateLink {
  /// The `average` option value.
  average,

  /// The `maximum` option value.
  maximum,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case AgateLink.average:
        return 'average';
      case AgateLink.maximum:
        return 'maximum';
    }
  }

  /// Parses a mpv wire string back into a [AgateLink].
  /// Unknown / empty input falls back to the first member.
  static AgateLink fromMpv(String? raw) {
    switch (raw) {
      case 'average':
        return AgateLink.average;
      case 'maximum':
        return AgateLink.maximum;
      default:
        return AgateLink.average;
    }
  }
}

/// Values for the `mode` option of the `agate` audio filter.
enum AgateMode {
  /// The `downward` option value.
  downward,

  /// The `upward` option value.
  upward,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case AgateMode.downward:
        return 'downward';
      case AgateMode.upward:
        return 'upward';
    }
  }

  /// Parses a mpv wire string back into a [AgateMode].
  /// Unknown / empty input falls back to the first member.
  static AgateMode fromMpv(String? raw) {
    switch (raw) {
      case 'downward':
        return AgateMode.downward;
      case 'upward':
        return AgateMode.upward;
      default:
        return AgateMode.downward;
    }
  }
}

/// Values for the `f` option of the `aiir` audio filter.
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
  sp,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case AiirFormat.ll:
        return 'll';
      case AiirFormat.sf:
        return 'sf';
      case AiirFormat.tf:
        return 'tf';
      case AiirFormat.zp:
        return 'zp';
      case AiirFormat.pr:
        return 'pr';
      case AiirFormat.pd:
        return 'pd';
      case AiirFormat.sp:
        return 'sp';
    }
  }

  /// Parses a mpv wire string back into a [AiirFormat].
  /// Unknown / empty input falls back to the first member.
  static AiirFormat fromMpv(String? raw) {
    switch (raw) {
      case 'll':
        return AiirFormat.ll;
      case 'sf':
        return AiirFormat.sf;
      case 'tf':
        return AiirFormat.tf;
      case 'zp':
        return AiirFormat.zp;
      case 'pr':
        return AiirFormat.pr;
      case 'pd':
        return AiirFormat.pd;
      case 'sp':
        return AiirFormat.sp;
      default:
        return AiirFormat.ll;
    }
  }
}

/// Values for the `e` option of the `aiir` audio filter.
enum AiirPrecision {
  /// double-precision floating-point
  dbl,

  /// single-precision floating-point
  flt,

  /// 32-bit integers
  i32,

  /// 16-bit integers
  i16,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case AiirPrecision.dbl:
        return 'dbl';
      case AiirPrecision.flt:
        return 'flt';
      case AiirPrecision.i32:
        return 'i32';
      case AiirPrecision.i16:
        return 'i16';
    }
  }

  /// Parses a mpv wire string back into a [AiirPrecision].
  /// Unknown / empty input falls back to the first member.
  static AiirPrecision fromMpv(String? raw) {
    switch (raw) {
      case 'dbl':
        return AiirPrecision.dbl;
      case 'flt':
        return AiirPrecision.flt;
      case 'i32':
        return AiirPrecision.i32;
      case 'i16':
        return AiirPrecision.i16;
      default:
        return AiirPrecision.dbl;
    }
  }
}

/// Values for the `process` option of the `aiir` audio filter.
enum AiirProcess {
  /// direct
  d,

  /// serial
  s,

  /// parallel
  p,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case AiirProcess.d:
        return 'd';
      case AiirProcess.s:
        return 's';
      case AiirProcess.p:
        return 'p';
    }
  }

  /// Parses a mpv wire string back into a [AiirProcess].
  /// Unknown / empty input falls back to the first member.
  static AiirProcess fromMpv(String? raw) {
    switch (raw) {
      case 'd':
        return AiirProcess.d;
      case 's':
        return AiirProcess.s;
      case 'p':
        return AiirProcess.p;
      default:
        return AiirProcess.d;
    }
  }
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
  f64,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case AllpassPrecision.auto:
        return 'auto';
      case AllpassPrecision.s16:
        return 's16';
      case AllpassPrecision.s32:
        return 's32';
      case AllpassPrecision.f32:
        return 'f32';
      case AllpassPrecision.f64:
        return 'f64';
    }
  }

  /// Parses a mpv wire string back into a [AllpassPrecision].
  /// Unknown / empty input falls back to the first member.
  static AllpassPrecision fromMpv(String? raw) {
    switch (raw) {
      case 'auto':
        return AllpassPrecision.auto;
      case 's16':
        return AllpassPrecision.s16;
      case 's32':
        return AllpassPrecision.s32;
      case 'f32':
        return AllpassPrecision.f32;
      case 'f64':
        return AllpassPrecision.f64;
      default:
        return AllpassPrecision.auto;
    }
  }
}

/// Values for the `a` option of the `allpass` audio filter.
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
  zdf,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case AllpassTransformType.di:
        return 'di';
      case AllpassTransformType.dii:
        return 'dii';
      case AllpassTransformType.tdi:
        return 'tdi';
      case AllpassTransformType.tdii:
        return 'tdii';
      case AllpassTransformType.latt:
        return 'latt';
      case AllpassTransformType.svf:
        return 'svf';
      case AllpassTransformType.zdf:
        return 'zdf';
    }
  }

  /// Parses a mpv wire string back into a [AllpassTransformType].
  /// Unknown / empty input falls back to the first member.
  static AllpassTransformType fromMpv(String? raw) {
    switch (raw) {
      case 'di':
        return AllpassTransformType.di;
      case 'dii':
        return AllpassTransformType.dii;
      case 'tdi':
        return AllpassTransformType.tdi;
      case 'tdii':
        return AllpassTransformType.tdii;
      case 'latt':
        return AllpassTransformType.latt;
      case 'svf':
        return AllpassTransformType.svf;
      case 'zdf':
        return AllpassTransformType.zdf;
      default:
        return AllpassTransformType.di;
    }
  }
}

/// Values for the `t` option of the `allpass` audio filter.
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
  k,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case AllpassWidthType.h:
        return 'h';
      case AllpassWidthType.q:
        return 'q';
      case AllpassWidthType.o:
        return 'o';
      case AllpassWidthType.s:
        return 's';
      case AllpassWidthType.k:
        return 'k';
    }
  }

  /// Parses a mpv wire string back into a [AllpassWidthType].
  /// Unknown / empty input falls back to the first member.
  static AllpassWidthType fromMpv(String? raw) {
    switch (raw) {
      case 'h':
        return AllpassWidthType.h;
      case 'q':
        return AllpassWidthType.q;
      case 'o':
        return AllpassWidthType.o;
      case 's':
        return AllpassWidthType.s;
      case 'k':
        return AllpassWidthType.k;
      default:
        return AllpassWidthType.h;
    }
  }
}

/// Values for the `fscale` option of the `anequalizer` audio filter.
enum AnequalizerFscale {
  /// linear
  lin,

  /// logarithmic
  log,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case AnequalizerFscale.lin:
        return 'lin';
      case AnequalizerFscale.log:
        return 'log';
    }
  }

  /// Parses a mpv wire string back into a [AnequalizerFscale].
  /// Unknown / empty input falls back to the first member.
  static AnequalizerFscale fromMpv(String? raw) {
    switch (raw) {
      case 'lin':
        return AnequalizerFscale.lin;
      case 'log':
        return AnequalizerFscale.log;
      default:
        return AnequalizerFscale.lin;
    }
  }
}

/// Values for the `o` option of the `anlmdn` audio filter.
enum AnlmdnMode {
  /// input
  i,

  /// output
  o,

  /// noise
  n,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case AnlmdnMode.i:
        return 'i';
      case AnlmdnMode.o:
        return 'o';
      case AnlmdnMode.n:
        return 'n';
    }
  }

  /// Parses a mpv wire string back into a [AnlmdnMode].
  /// Unknown / empty input falls back to the first member.
  static AnlmdnMode fromMpv(String? raw) {
    switch (raw) {
      case 'i':
        return AnlmdnMode.i;
      case 'o':
        return AnlmdnMode.o;
      case 'n':
        return AnlmdnMode.n;
      default:
        return AnlmdnMode.i;
    }
  }
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
  s,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case AphaserType.triangular:
        return 'triangular';
      case AphaserType.t:
        return 't';
      case AphaserType.sinusoidal:
        return 'sinusoidal';
      case AphaserType.s:
        return 's';
    }
  }

  /// Parses a mpv wire string back into a [AphaserType].
  /// Unknown / empty input falls back to the first member.
  static AphaserType fromMpv(String? raw) {
    switch (raw) {
      case 'triangular':
        return AphaserType.triangular;
      case 't':
        return AphaserType.t;
      case 'sinusoidal':
        return AphaserType.sinusoidal;
      case 's':
        return AphaserType.s;
      default:
        return AphaserType.triangular;
    }
  }
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
  sawdown,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case ApulsatorMode.sine:
        return 'sine';
      case ApulsatorMode.triangle:
        return 'triangle';
      case ApulsatorMode.square:
        return 'square';
      case ApulsatorMode.sawup:
        return 'sawup';
      case ApulsatorMode.sawdown:
        return 'sawdown';
    }
  }

  /// Parses a mpv wire string back into a [ApulsatorMode].
  /// Unknown / empty input falls back to the first member.
  static ApulsatorMode fromMpv(String? raw) {
    switch (raw) {
      case 'sine':
        return ApulsatorMode.sine;
      case 'triangle':
        return ApulsatorMode.triangle;
      case 'square':
        return ApulsatorMode.square;
      case 'sawup':
        return ApulsatorMode.sawup;
      case 'sawdown':
        return ApulsatorMode.sawdown;
      default:
        return ApulsatorMode.sine;
    }
  }
}

/// Values for the `timing` option of the `apulsator` audio filter.
enum ApulsatorTiming {
  /// The `bpm` option value.
  bpm,

  /// The `ms` option value.
  ms,

  /// The `hz` option value.
  hz,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case ApulsatorTiming.bpm:
        return 'bpm';
      case ApulsatorTiming.ms:
        return 'ms';
      case ApulsatorTiming.hz:
        return 'hz';
    }
  }

  /// Parses a mpv wire string back into a [ApulsatorTiming].
  /// Unknown / empty input falls back to the first member.
  static ApulsatorTiming fromMpv(String? raw) {
    switch (raw) {
      case 'bpm':
        return ApulsatorTiming.bpm;
      case 'ms':
        return ApulsatorTiming.ms;
      case 'hz':
        return ApulsatorTiming.hz;
      default:
        return ApulsatorTiming.bpm;
    }
  }
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
  erf,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case AsoftclipTypes.hard:
        return 'hard';
      case AsoftclipTypes.tanh:
        return 'tanh';
      case AsoftclipTypes.atan:
        return 'atan';
      case AsoftclipTypes.cubic:
        return 'cubic';
      case AsoftclipTypes.exp:
        return 'exp';
      case AsoftclipTypes.alg:
        return 'alg';
      case AsoftclipTypes.quintic:
        return 'quintic';
      case AsoftclipTypes.sin:
        return 'sin';
      case AsoftclipTypes.erf:
        return 'erf';
    }
  }

  /// Parses a mpv wire string back into a [AsoftclipTypes].
  /// Unknown / empty input falls back to the first member.
  static AsoftclipTypes fromMpv(String? raw) {
    switch (raw) {
      case 'hard':
        return AsoftclipTypes.hard;
      case 'tanh':
        return AsoftclipTypes.tanh;
      case 'atan':
        return AsoftclipTypes.atan;
      case 'cubic':
        return AsoftclipTypes.cubic;
      case 'exp':
        return AsoftclipTypes.exp;
      case 'alg':
        return AsoftclipTypes.alg;
      case 'quintic':
        return AsoftclipTypes.quintic;
      case 'sin':
        return AsoftclipTypes.sin;
      case 'erf':
        return AsoftclipTypes.erf;
      default:
        return AsoftclipTypes.hard;
    }
  }
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
  f64,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case BandpassPrecision.auto:
        return 'auto';
      case BandpassPrecision.s16:
        return 's16';
      case BandpassPrecision.s32:
        return 's32';
      case BandpassPrecision.f32:
        return 'f32';
      case BandpassPrecision.f64:
        return 'f64';
    }
  }

  /// Parses a mpv wire string back into a [BandpassPrecision].
  /// Unknown / empty input falls back to the first member.
  static BandpassPrecision fromMpv(String? raw) {
    switch (raw) {
      case 'auto':
        return BandpassPrecision.auto;
      case 's16':
        return BandpassPrecision.s16;
      case 's32':
        return BandpassPrecision.s32;
      case 'f32':
        return BandpassPrecision.f32;
      case 'f64':
        return BandpassPrecision.f64;
      default:
        return BandpassPrecision.auto;
    }
  }
}

/// Values for the `a` option of the `bandpass` audio filter.
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
  zdf,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case BandpassTransformType.di:
        return 'di';
      case BandpassTransformType.dii:
        return 'dii';
      case BandpassTransformType.tdi:
        return 'tdi';
      case BandpassTransformType.tdii:
        return 'tdii';
      case BandpassTransformType.latt:
        return 'latt';
      case BandpassTransformType.svf:
        return 'svf';
      case BandpassTransformType.zdf:
        return 'zdf';
    }
  }

  /// Parses a mpv wire string back into a [BandpassTransformType].
  /// Unknown / empty input falls back to the first member.
  static BandpassTransformType fromMpv(String? raw) {
    switch (raw) {
      case 'di':
        return BandpassTransformType.di;
      case 'dii':
        return BandpassTransformType.dii;
      case 'tdi':
        return BandpassTransformType.tdi;
      case 'tdii':
        return BandpassTransformType.tdii;
      case 'latt':
        return BandpassTransformType.latt;
      case 'svf':
        return BandpassTransformType.svf;
      case 'zdf':
        return BandpassTransformType.zdf;
      default:
        return BandpassTransformType.di;
    }
  }
}

/// Values for the `t` option of the `bandpass` audio filter.
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
  k,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case BandpassWidthType.h:
        return 'h';
      case BandpassWidthType.q:
        return 'q';
      case BandpassWidthType.o:
        return 'o';
      case BandpassWidthType.s:
        return 's';
      case BandpassWidthType.k:
        return 'k';
    }
  }

  /// Parses a mpv wire string back into a [BandpassWidthType].
  /// Unknown / empty input falls back to the first member.
  static BandpassWidthType fromMpv(String? raw) {
    switch (raw) {
      case 'h':
        return BandpassWidthType.h;
      case 'q':
        return BandpassWidthType.q;
      case 'o':
        return BandpassWidthType.o;
      case 's':
        return BandpassWidthType.s;
      case 'k':
        return BandpassWidthType.k;
      default:
        return BandpassWidthType.h;
    }
  }
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
  f64,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case BandrejectPrecision.auto:
        return 'auto';
      case BandrejectPrecision.s16:
        return 's16';
      case BandrejectPrecision.s32:
        return 's32';
      case BandrejectPrecision.f32:
        return 'f32';
      case BandrejectPrecision.f64:
        return 'f64';
    }
  }

  /// Parses a mpv wire string back into a [BandrejectPrecision].
  /// Unknown / empty input falls back to the first member.
  static BandrejectPrecision fromMpv(String? raw) {
    switch (raw) {
      case 'auto':
        return BandrejectPrecision.auto;
      case 's16':
        return BandrejectPrecision.s16;
      case 's32':
        return BandrejectPrecision.s32;
      case 'f32':
        return BandrejectPrecision.f32;
      case 'f64':
        return BandrejectPrecision.f64;
      default:
        return BandrejectPrecision.auto;
    }
  }
}

/// Values for the `a` option of the `bandreject` audio filter.
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
  zdf,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case BandrejectTransformType.di:
        return 'di';
      case BandrejectTransformType.dii:
        return 'dii';
      case BandrejectTransformType.tdi:
        return 'tdi';
      case BandrejectTransformType.tdii:
        return 'tdii';
      case BandrejectTransformType.latt:
        return 'latt';
      case BandrejectTransformType.svf:
        return 'svf';
      case BandrejectTransformType.zdf:
        return 'zdf';
    }
  }

  /// Parses a mpv wire string back into a [BandrejectTransformType].
  /// Unknown / empty input falls back to the first member.
  static BandrejectTransformType fromMpv(String? raw) {
    switch (raw) {
      case 'di':
        return BandrejectTransformType.di;
      case 'dii':
        return BandrejectTransformType.dii;
      case 'tdi':
        return BandrejectTransformType.tdi;
      case 'tdii':
        return BandrejectTransformType.tdii;
      case 'latt':
        return BandrejectTransformType.latt;
      case 'svf':
        return BandrejectTransformType.svf;
      case 'zdf':
        return BandrejectTransformType.zdf;
      default:
        return BandrejectTransformType.di;
    }
  }
}

/// Values for the `t` option of the `bandreject` audio filter.
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
  k,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case BandrejectWidthType.h:
        return 'h';
      case BandrejectWidthType.q:
        return 'q';
      case BandrejectWidthType.o:
        return 'o';
      case BandrejectWidthType.s:
        return 's';
      case BandrejectWidthType.k:
        return 'k';
    }
  }

  /// Parses a mpv wire string back into a [BandrejectWidthType].
  /// Unknown / empty input falls back to the first member.
  static BandrejectWidthType fromMpv(String? raw) {
    switch (raw) {
      case 'h':
        return BandrejectWidthType.h;
      case 'q':
        return BandrejectWidthType.q;
      case 'o':
        return BandrejectWidthType.o;
      case 's':
        return BandrejectWidthType.s;
      case 'k':
        return BandrejectWidthType.k;
      default:
        return BandrejectWidthType.h;
    }
  }
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
  f64,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case BassPrecision.auto:
        return 'auto';
      case BassPrecision.s16:
        return 's16';
      case BassPrecision.s32:
        return 's32';
      case BassPrecision.f32:
        return 'f32';
      case BassPrecision.f64:
        return 'f64';
    }
  }

  /// Parses a mpv wire string back into a [BassPrecision].
  /// Unknown / empty input falls back to the first member.
  static BassPrecision fromMpv(String? raw) {
    switch (raw) {
      case 'auto':
        return BassPrecision.auto;
      case 's16':
        return BassPrecision.s16;
      case 's32':
        return BassPrecision.s32;
      case 'f32':
        return BassPrecision.f32;
      case 'f64':
        return BassPrecision.f64;
      default:
        return BassPrecision.auto;
    }
  }
}

/// Values for the `a` option of the `bass` audio filter.
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
  zdf,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case BassTransformType.di:
        return 'di';
      case BassTransformType.dii:
        return 'dii';
      case BassTransformType.tdi:
        return 'tdi';
      case BassTransformType.tdii:
        return 'tdii';
      case BassTransformType.latt:
        return 'latt';
      case BassTransformType.svf:
        return 'svf';
      case BassTransformType.zdf:
        return 'zdf';
    }
  }

  /// Parses a mpv wire string back into a [BassTransformType].
  /// Unknown / empty input falls back to the first member.
  static BassTransformType fromMpv(String? raw) {
    switch (raw) {
      case 'di':
        return BassTransformType.di;
      case 'dii':
        return BassTransformType.dii;
      case 'tdi':
        return BassTransformType.tdi;
      case 'tdii':
        return BassTransformType.tdii;
      case 'latt':
        return BassTransformType.latt;
      case 'svf':
        return BassTransformType.svf;
      case 'zdf':
        return BassTransformType.zdf;
      default:
        return BassTransformType.di;
    }
  }
}

/// Values for the `t` option of the `bass` audio filter.
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
  k,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case BassWidthType.h:
        return 'h';
      case BassWidthType.q:
        return 'q';
      case BassWidthType.o:
        return 'o';
      case BassWidthType.s:
        return 's';
      case BassWidthType.k:
        return 'k';
    }
  }

  /// Parses a mpv wire string back into a [BassWidthType].
  /// Unknown / empty input falls back to the first member.
  static BassWidthType fromMpv(String? raw) {
    switch (raw) {
      case 'h':
        return BassWidthType.h;
      case 'q':
        return BassWidthType.q;
      case 'o':
        return BassWidthType.o;
      case 's':
        return BassWidthType.s;
      case 'k':
        return BassWidthType.k;
      default:
        return BassWidthType.h;
    }
  }
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
  f64,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case BiquadPrecision.auto:
        return 'auto';
      case BiquadPrecision.s16:
        return 's16';
      case BiquadPrecision.s32:
        return 's32';
      case BiquadPrecision.f32:
        return 'f32';
      case BiquadPrecision.f64:
        return 'f64';
    }
  }

  /// Parses a mpv wire string back into a [BiquadPrecision].
  /// Unknown / empty input falls back to the first member.
  static BiquadPrecision fromMpv(String? raw) {
    switch (raw) {
      case 'auto':
        return BiquadPrecision.auto;
      case 's16':
        return BiquadPrecision.s16;
      case 's32':
        return BiquadPrecision.s32;
      case 'f32':
        return BiquadPrecision.f32;
      case 'f64':
        return BiquadPrecision.f64;
      default:
        return BiquadPrecision.auto;
    }
  }
}

/// Values for the `a` option of the `biquad` audio filter.
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
  zdf,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case BiquadTransformType.di:
        return 'di';
      case BiquadTransformType.dii:
        return 'dii';
      case BiquadTransformType.tdi:
        return 'tdi';
      case BiquadTransformType.tdii:
        return 'tdii';
      case BiquadTransformType.latt:
        return 'latt';
      case BiquadTransformType.svf:
        return 'svf';
      case BiquadTransformType.zdf:
        return 'zdf';
    }
  }

  /// Parses a mpv wire string back into a [BiquadTransformType].
  /// Unknown / empty input falls back to the first member.
  static BiquadTransformType fromMpv(String? raw) {
    switch (raw) {
      case 'di':
        return BiquadTransformType.di;
      case 'dii':
        return BiquadTransformType.dii;
      case 'tdi':
        return BiquadTransformType.tdi;
      case 'tdii':
        return BiquadTransformType.tdii;
      case 'latt':
        return BiquadTransformType.latt;
      case 'svf':
        return BiquadTransformType.svf;
      case 'zdf':
        return BiquadTransformType.zdf;
      default:
        return BiquadTransformType.di;
    }
  }
}

/// Values for the `s` option of the `deesser` audio filter.
enum DeesserMode {
  /// input
  i,

  /// output
  o,

  /// ess
  e,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case DeesserMode.i:
        return 'i';
      case DeesserMode.o:
        return 'o';
      case DeesserMode.e:
        return 'e';
    }
  }

  /// Parses a mpv wire string back into a [DeesserMode].
  /// Unknown / empty input falls back to the first member.
  static DeesserMode fromMpv(String? raw) {
    switch (raw) {
      case 'i':
        return DeesserMode.i;
      case 'o':
        return DeesserMode.o;
      case 'e':
        return DeesserMode.e;
      default:
        return DeesserMode.i;
    }
  }
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
  s,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case Ebur128Gaugetype.momentary:
        return 'momentary';
      case Ebur128Gaugetype.m:
        return 'm';
      case Ebur128Gaugetype.shortterm:
        return 'shortterm';
      case Ebur128Gaugetype.s:
        return 's';
    }
  }

  /// Parses a mpv wire string back into a [Ebur128Gaugetype].
  /// Unknown / empty input falls back to the first member.
  static Ebur128Gaugetype fromMpv(String? raw) {
    switch (raw) {
      case 'momentary':
        return Ebur128Gaugetype.momentary;
      case 'm':
        return Ebur128Gaugetype.m;
      case 'shortterm':
        return Ebur128Gaugetype.shortterm;
      case 's':
        return Ebur128Gaugetype.s;
      default:
        return Ebur128Gaugetype.momentary;
    }
  }
}

/// Values for the `framelog` option of the `ebur128` audio filter.
enum Ebur128Level {
  /// logging disabled
  quiet,

  /// information logging level
  info,

  /// verbose logging level
  verbose,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case Ebur128Level.quiet:
        return 'quiet';
      case Ebur128Level.info:
        return 'info';
      case Ebur128Level.verbose:
        return 'verbose';
    }
  }

  /// Parses a mpv wire string back into a [Ebur128Level].
  /// Unknown / empty input falls back to the first member.
  static Ebur128Level fromMpv(String? raw) {
    switch (raw) {
      case 'quiet':
        return Ebur128Level.quiet;
      case 'info':
        return Ebur128Level.info;
      case 'verbose':
        return Ebur128Level.verbose;
      default:
        return Ebur128Level.quiet;
    }
  }
}

/// Values for the `peak` option of the `ebur128` audio filter.
enum Ebur128Mode {
  /// disable any peak mode
  none,

  /// enable peak-sample mode
  sample,

  /// enable true-peak mode
  true_,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case Ebur128Mode.none:
        return 'none';
      case Ebur128Mode.sample:
        return 'sample';
      case Ebur128Mode.true_:
        return 'true';
    }
  }

  /// Parses a mpv wire string back into a [Ebur128Mode].
  /// Unknown / empty input falls back to the first member.
  static Ebur128Mode fromMpv(String? raw) {
    switch (raw) {
      case 'none':
        return Ebur128Mode.none;
      case 'sample':
        return Ebur128Mode.sample;
      case 'true':
        return Ebur128Mode.true_;
      default:
        return Ebur128Mode.none;
    }
  }
}

/// Values for the `scale` option of the `ebur128` audio filter.
enum Ebur128Scaletype {
  /// display absolute values (LUFS)
  absolute,

  /// display absolute values (LUFS)
  LUFS,

  /// display values relative to target (LU)
  relative,

  /// display values relative to target (LU)
  LU,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case Ebur128Scaletype.absolute:
        return 'absolute';
      case Ebur128Scaletype.LUFS:
        return 'LUFS';
      case Ebur128Scaletype.relative:
        return 'relative';
      case Ebur128Scaletype.LU:
        return 'LU';
    }
  }

  /// Parses a mpv wire string back into a [Ebur128Scaletype].
  /// Unknown / empty input falls back to the first member.
  static Ebur128Scaletype fromMpv(String? raw) {
    switch (raw) {
      case 'absolute':
        return Ebur128Scaletype.absolute;
      case 'LUFS':
        return Ebur128Scaletype.LUFS;
      case 'relative':
        return Ebur128Scaletype.relative;
      case 'LU':
        return Ebur128Scaletype.LU;
      default:
        return Ebur128Scaletype.absolute;
    }
  }
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
  f64,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case EqualizerPrecision.auto:
        return 'auto';
      case EqualizerPrecision.s16:
        return 's16';
      case EqualizerPrecision.s32:
        return 's32';
      case EqualizerPrecision.f32:
        return 'f32';
      case EqualizerPrecision.f64:
        return 'f64';
    }
  }

  /// Parses a mpv wire string back into a [EqualizerPrecision].
  /// Unknown / empty input falls back to the first member.
  static EqualizerPrecision fromMpv(String? raw) {
    switch (raw) {
      case 'auto':
        return EqualizerPrecision.auto;
      case 's16':
        return EqualizerPrecision.s16;
      case 's32':
        return EqualizerPrecision.s32;
      case 'f32':
        return EqualizerPrecision.f32;
      case 'f64':
        return EqualizerPrecision.f64;
      default:
        return EqualizerPrecision.auto;
    }
  }
}

/// Values for the `a` option of the `equalizer` audio filter.
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
  zdf,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case EqualizerTransformType.di:
        return 'di';
      case EqualizerTransformType.dii:
        return 'dii';
      case EqualizerTransformType.tdi:
        return 'tdi';
      case EqualizerTransformType.tdii:
        return 'tdii';
      case EqualizerTransformType.latt:
        return 'latt';
      case EqualizerTransformType.svf:
        return 'svf';
      case EqualizerTransformType.zdf:
        return 'zdf';
    }
  }

  /// Parses a mpv wire string back into a [EqualizerTransformType].
  /// Unknown / empty input falls back to the first member.
  static EqualizerTransformType fromMpv(String? raw) {
    switch (raw) {
      case 'di':
        return EqualizerTransformType.di;
      case 'dii':
        return EqualizerTransformType.dii;
      case 'tdi':
        return EqualizerTransformType.tdi;
      case 'tdii':
        return EqualizerTransformType.tdii;
      case 'latt':
        return EqualizerTransformType.latt;
      case 'svf':
        return EqualizerTransformType.svf;
      case 'zdf':
        return EqualizerTransformType.zdf;
      default:
        return EqualizerTransformType.di;
    }
  }
}

/// Values for the `t` option of the `equalizer` audio filter.
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
  k,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case EqualizerWidthType.h:
        return 'h';
      case EqualizerWidthType.q:
        return 'q';
      case EqualizerWidthType.o:
        return 'o';
      case EqualizerWidthType.s:
        return 's';
      case EqualizerWidthType.k:
        return 'k';
    }
  }

  /// Parses a mpv wire string back into a [EqualizerWidthType].
  /// Unknown / empty input falls back to the first member.
  static EqualizerWidthType fromMpv(String? raw) {
    switch (raw) {
      case 'h':
        return EqualizerWidthType.h;
      case 'q':
        return EqualizerWidthType.q;
      case 'o':
        return EqualizerWidthType.o;
      case 's':
        return EqualizerWidthType.s;
      case 'k':
        return EqualizerWidthType.k;
      default:
        return EqualizerWidthType.h;
    }
  }
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
  loglog,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case FirequalizerScale.linlin:
        return 'linlin';
      case FirequalizerScale.linlog:
        return 'linlog';
      case FirequalizerScale.loglin:
        return 'loglin';
      case FirequalizerScale.loglog:
        return 'loglog';
    }
  }

  /// Parses a mpv wire string back into a [FirequalizerScale].
  /// Unknown / empty input falls back to the first member.
  static FirequalizerScale fromMpv(String? raw) {
    switch (raw) {
      case 'linlin':
        return FirequalizerScale.linlin;
      case 'linlog':
        return FirequalizerScale.linlog;
      case 'loglin':
        return FirequalizerScale.loglin;
      case 'loglog':
        return FirequalizerScale.loglog;
      default:
        return FirequalizerScale.linlin;
    }
  }
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
  tukey,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case FirequalizerWfunc.rectangular:
        return 'rectangular';
      case FirequalizerWfunc.hann:
        return 'hann';
      case FirequalizerWfunc.hamming:
        return 'hamming';
      case FirequalizerWfunc.blackman:
        return 'blackman';
      case FirequalizerWfunc.nuttall3:
        return 'nuttall3';
      case FirequalizerWfunc.mnuttall3:
        return 'mnuttall3';
      case FirequalizerWfunc.nuttall:
        return 'nuttall';
      case FirequalizerWfunc.bnuttall:
        return 'bnuttall';
      case FirequalizerWfunc.bharris:
        return 'bharris';
      case FirequalizerWfunc.tukey:
        return 'tukey';
    }
  }

  /// Parses a mpv wire string back into a [FirequalizerWfunc].
  /// Unknown / empty input falls back to the first member.
  static FirequalizerWfunc fromMpv(String? raw) {
    switch (raw) {
      case 'rectangular':
        return FirequalizerWfunc.rectangular;
      case 'hann':
        return FirequalizerWfunc.hann;
      case 'hamming':
        return FirequalizerWfunc.hamming;
      case 'blackman':
        return FirequalizerWfunc.blackman;
      case 'nuttall3':
        return FirequalizerWfunc.nuttall3;
      case 'mnuttall3':
        return FirequalizerWfunc.mnuttall3;
      case 'nuttall':
        return FirequalizerWfunc.nuttall;
      case 'bnuttall':
        return FirequalizerWfunc.bnuttall;
      case 'bharris':
        return FirequalizerWfunc.bharris;
      case 'tukey':
        return FirequalizerWfunc.tukey;
      default:
        return FirequalizerWfunc.rectangular;
    }
  }
}

/// Values for the `interp` option of the `flanger` audio filter.
enum FlangerItype {
  /// The `linear` option value.
  linear,

  /// The `quadratic` option value.
  quadratic,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case FlangerItype.linear:
        return 'linear';
      case FlangerItype.quadratic:
        return 'quadratic';
    }
  }

  /// Parses a mpv wire string back into a [FlangerItype].
  /// Unknown / empty input falls back to the first member.
  static FlangerItype fromMpv(String? raw) {
    switch (raw) {
      case 'linear':
        return FlangerItype.linear;
      case 'quadratic':
        return FlangerItype.quadratic;
      default:
        return FlangerItype.linear;
    }
  }
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
  s,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case FlangerType.triangular:
        return 'triangular';
      case FlangerType.t:
        return 't';
      case FlangerType.sinusoidal:
        return 'sinusoidal';
      case FlangerType.s:
        return 's';
    }
  }

  /// Parses a mpv wire string back into a [FlangerType].
  /// Unknown / empty input falls back to the first member.
  static FlangerType fromMpv(String? raw) {
    switch (raw) {
      case 'triangular':
        return FlangerType.triangular;
      case 't':
        return FlangerType.t;
      case 'sinusoidal':
        return FlangerType.sinusoidal;
      case 's':
        return FlangerType.s;
      default:
        return FlangerType.triangular;
    }
  }
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
  side,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case HaasSource.left:
        return 'left';
      case HaasSource.right:
        return 'right';
      case HaasSource.mid:
        return 'mid';
      case HaasSource.side:
        return 'side';
    }
  }

  /// Parses a mpv wire string back into a [HaasSource].
  /// Unknown / empty input falls back to the first member.
  static HaasSource fromMpv(String? raw) {
    switch (raw) {
      case 'left':
        return HaasSource.left;
      case 'right':
        return HaasSource.right;
      case 'mid':
        return HaasSource.mid;
      case 'side':
        return HaasSource.side;
      default:
        return HaasSource.left;
    }
  }
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
  tgm,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case HdcdAnalyzeMode.off:
        return 'off';
      case HdcdAnalyzeMode.lle:
        return 'lle';
      case HdcdAnalyzeMode.pe:
        return 'pe';
      case HdcdAnalyzeMode.cdt:
        return 'cdt';
      case HdcdAnalyzeMode.tgm:
        return 'tgm';
    }
  }

  /// Parses a mpv wire string back into a [HdcdAnalyzeMode].
  /// Unknown / empty input falls back to the first member.
  static HdcdAnalyzeMode fromMpv(String? raw) {
    switch (raw) {
      case 'off':
        return HdcdAnalyzeMode.off;
      case 'lle':
        return HdcdAnalyzeMode.lle;
      case 'pe':
        return HdcdAnalyzeMode.pe;
      case 'cdt':
        return HdcdAnalyzeMode.cdt;
      case 'tgm':
        return HdcdAnalyzeMode.tgm;
      default:
        return HdcdAnalyzeMode.off;
    }
  }
}

/// Values for the `bits_per_sample` option of the `hdcd` audio filter.
enum HdcdBitsPerSample {
  /// 16-bit (in s32 or s16)
  n16,

  /// 20-bit (in s32)
  n20,

  /// 24-bit (in s32)
  n24,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case HdcdBitsPerSample.n16:
        return '16';
      case HdcdBitsPerSample.n20:
        return '20';
      case HdcdBitsPerSample.n24:
        return '24';
    }
  }

  /// Parses a mpv wire string back into a [HdcdBitsPerSample].
  /// Unknown / empty input falls back to the first member.
  static HdcdBitsPerSample fromMpv(String? raw) {
    switch (raw) {
      case '16':
        return HdcdBitsPerSample.n16;
      case '20':
        return HdcdBitsPerSample.n20;
      case '24':
        return HdcdBitsPerSample.n24;
      default:
        return HdcdBitsPerSample.n16;
    }
  }
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
  f64,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case HighpassPrecision.auto:
        return 'auto';
      case HighpassPrecision.s16:
        return 's16';
      case HighpassPrecision.s32:
        return 's32';
      case HighpassPrecision.f32:
        return 'f32';
      case HighpassPrecision.f64:
        return 'f64';
    }
  }

  /// Parses a mpv wire string back into a [HighpassPrecision].
  /// Unknown / empty input falls back to the first member.
  static HighpassPrecision fromMpv(String? raw) {
    switch (raw) {
      case 'auto':
        return HighpassPrecision.auto;
      case 's16':
        return HighpassPrecision.s16;
      case 's32':
        return HighpassPrecision.s32;
      case 'f32':
        return HighpassPrecision.f32;
      case 'f64':
        return HighpassPrecision.f64;
      default:
        return HighpassPrecision.auto;
    }
  }
}

/// Values for the `a` option of the `highpass` audio filter.
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
  zdf,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case HighpassTransformType.di:
        return 'di';
      case HighpassTransformType.dii:
        return 'dii';
      case HighpassTransformType.tdi:
        return 'tdi';
      case HighpassTransformType.tdii:
        return 'tdii';
      case HighpassTransformType.latt:
        return 'latt';
      case HighpassTransformType.svf:
        return 'svf';
      case HighpassTransformType.zdf:
        return 'zdf';
    }
  }

  /// Parses a mpv wire string back into a [HighpassTransformType].
  /// Unknown / empty input falls back to the first member.
  static HighpassTransformType fromMpv(String? raw) {
    switch (raw) {
      case 'di':
        return HighpassTransformType.di;
      case 'dii':
        return HighpassTransformType.dii;
      case 'tdi':
        return HighpassTransformType.tdi;
      case 'tdii':
        return HighpassTransformType.tdii;
      case 'latt':
        return HighpassTransformType.latt;
      case 'svf':
        return HighpassTransformType.svf;
      case 'zdf':
        return HighpassTransformType.zdf;
      default:
        return HighpassTransformType.di;
    }
  }
}

/// Values for the `t` option of the `highpass` audio filter.
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
  k,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case HighpassWidthType.h:
        return 'h';
      case HighpassWidthType.q:
        return 'q';
      case HighpassWidthType.o:
        return 'o';
      case HighpassWidthType.s:
        return 's';
      case HighpassWidthType.k:
        return 'k';
    }
  }

  /// Parses a mpv wire string back into a [HighpassWidthType].
  /// Unknown / empty input falls back to the first member.
  static HighpassWidthType fromMpv(String? raw) {
    switch (raw) {
      case 'h':
        return HighpassWidthType.h;
      case 'q':
        return HighpassWidthType.q;
      case 'o':
        return HighpassWidthType.o;
      case 's':
        return HighpassWidthType.s;
      case 'k':
        return HighpassWidthType.k;
      default:
        return HighpassWidthType.h;
    }
  }
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
  f64,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case HighshelfPrecision.auto:
        return 'auto';
      case HighshelfPrecision.s16:
        return 's16';
      case HighshelfPrecision.s32:
        return 's32';
      case HighshelfPrecision.f32:
        return 'f32';
      case HighshelfPrecision.f64:
        return 'f64';
    }
  }

  /// Parses a mpv wire string back into a [HighshelfPrecision].
  /// Unknown / empty input falls back to the first member.
  static HighshelfPrecision fromMpv(String? raw) {
    switch (raw) {
      case 'auto':
        return HighshelfPrecision.auto;
      case 's16':
        return HighshelfPrecision.s16;
      case 's32':
        return HighshelfPrecision.s32;
      case 'f32':
        return HighshelfPrecision.f32;
      case 'f64':
        return HighshelfPrecision.f64;
      default:
        return HighshelfPrecision.auto;
    }
  }
}

/// Values for the `a` option of the `highshelf` audio filter.
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
  zdf,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case HighshelfTransformType.di:
        return 'di';
      case HighshelfTransformType.dii:
        return 'dii';
      case HighshelfTransformType.tdi:
        return 'tdi';
      case HighshelfTransformType.tdii:
        return 'tdii';
      case HighshelfTransformType.latt:
        return 'latt';
      case HighshelfTransformType.svf:
        return 'svf';
      case HighshelfTransformType.zdf:
        return 'zdf';
    }
  }

  /// Parses a mpv wire string back into a [HighshelfTransformType].
  /// Unknown / empty input falls back to the first member.
  static HighshelfTransformType fromMpv(String? raw) {
    switch (raw) {
      case 'di':
        return HighshelfTransformType.di;
      case 'dii':
        return HighshelfTransformType.dii;
      case 'tdi':
        return HighshelfTransformType.tdi;
      case 'tdii':
        return HighshelfTransformType.tdii;
      case 'latt':
        return HighshelfTransformType.latt;
      case 'svf':
        return HighshelfTransformType.svf;
      case 'zdf':
        return HighshelfTransformType.zdf;
      default:
        return HighshelfTransformType.di;
    }
  }
}

/// Values for the `t` option of the `highshelf` audio filter.
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
  k,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case HighshelfWidthType.h:
        return 'h';
      case HighshelfWidthType.q:
        return 'q';
      case HighshelfWidthType.o:
        return 'o';
      case HighshelfWidthType.s:
        return 's';
      case HighshelfWidthType.k:
        return 'k';
    }
  }

  /// Parses a mpv wire string back into a [HighshelfWidthType].
  /// Unknown / empty input falls back to the first member.
  static HighshelfWidthType fromMpv(String? raw) {
    switch (raw) {
      case 'h':
        return HighshelfWidthType.h;
      case 'q':
        return HighshelfWidthType.q;
      case 'o':
        return HighshelfWidthType.o;
      case 's':
        return HighshelfWidthType.s;
      case 'k':
        return HighshelfWidthType.k;
      default:
        return HighshelfWidthType.h;
    }
  }
}

/// Values for the `print_format` option of the `loudnorm` audio filter.
enum LoudnormPrintFormat {
  /// The `none` option value.
  none,

  /// The `json` option value.
  json,

  /// The `summary` option value.
  summary,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case LoudnormPrintFormat.none:
        return 'none';
      case LoudnormPrintFormat.json:
        return 'json';
      case LoudnormPrintFormat.summary:
        return 'summary';
    }
  }

  /// Parses a mpv wire string back into a [LoudnormPrintFormat].
  /// Unknown / empty input falls back to the first member.
  static LoudnormPrintFormat fromMpv(String? raw) {
    switch (raw) {
      case 'none':
        return LoudnormPrintFormat.none;
      case 'json':
        return LoudnormPrintFormat.json;
      case 'summary':
        return LoudnormPrintFormat.summary;
      default:
        return LoudnormPrintFormat.none;
    }
  }
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
  f64,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case LowpassPrecision.auto:
        return 'auto';
      case LowpassPrecision.s16:
        return 's16';
      case LowpassPrecision.s32:
        return 's32';
      case LowpassPrecision.f32:
        return 'f32';
      case LowpassPrecision.f64:
        return 'f64';
    }
  }

  /// Parses a mpv wire string back into a [LowpassPrecision].
  /// Unknown / empty input falls back to the first member.
  static LowpassPrecision fromMpv(String? raw) {
    switch (raw) {
      case 'auto':
        return LowpassPrecision.auto;
      case 's16':
        return LowpassPrecision.s16;
      case 's32':
        return LowpassPrecision.s32;
      case 'f32':
        return LowpassPrecision.f32;
      case 'f64':
        return LowpassPrecision.f64;
      default:
        return LowpassPrecision.auto;
    }
  }
}

/// Values for the `a` option of the `lowpass` audio filter.
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
  zdf,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case LowpassTransformType.di:
        return 'di';
      case LowpassTransformType.dii:
        return 'dii';
      case LowpassTransformType.tdi:
        return 'tdi';
      case LowpassTransformType.tdii:
        return 'tdii';
      case LowpassTransformType.latt:
        return 'latt';
      case LowpassTransformType.svf:
        return 'svf';
      case LowpassTransformType.zdf:
        return 'zdf';
    }
  }

  /// Parses a mpv wire string back into a [LowpassTransformType].
  /// Unknown / empty input falls back to the first member.
  static LowpassTransformType fromMpv(String? raw) {
    switch (raw) {
      case 'di':
        return LowpassTransformType.di;
      case 'dii':
        return LowpassTransformType.dii;
      case 'tdi':
        return LowpassTransformType.tdi;
      case 'tdii':
        return LowpassTransformType.tdii;
      case 'latt':
        return LowpassTransformType.latt;
      case 'svf':
        return LowpassTransformType.svf;
      case 'zdf':
        return LowpassTransformType.zdf;
      default:
        return LowpassTransformType.di;
    }
  }
}

/// Values for the `t` option of the `lowpass` audio filter.
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
  k,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case LowpassWidthType.h:
        return 'h';
      case LowpassWidthType.q:
        return 'q';
      case LowpassWidthType.o:
        return 'o';
      case LowpassWidthType.s:
        return 's';
      case LowpassWidthType.k:
        return 'k';
    }
  }

  /// Parses a mpv wire string back into a [LowpassWidthType].
  /// Unknown / empty input falls back to the first member.
  static LowpassWidthType fromMpv(String? raw) {
    switch (raw) {
      case 'h':
        return LowpassWidthType.h;
      case 'q':
        return LowpassWidthType.q;
      case 'o':
        return LowpassWidthType.o;
      case 's':
        return LowpassWidthType.s;
      case 'k':
        return LowpassWidthType.k;
      default:
        return LowpassWidthType.h;
    }
  }
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
  f64,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case LowshelfPrecision.auto:
        return 'auto';
      case LowshelfPrecision.s16:
        return 's16';
      case LowshelfPrecision.s32:
        return 's32';
      case LowshelfPrecision.f32:
        return 'f32';
      case LowshelfPrecision.f64:
        return 'f64';
    }
  }

  /// Parses a mpv wire string back into a [LowshelfPrecision].
  /// Unknown / empty input falls back to the first member.
  static LowshelfPrecision fromMpv(String? raw) {
    switch (raw) {
      case 'auto':
        return LowshelfPrecision.auto;
      case 's16':
        return LowshelfPrecision.s16;
      case 's32':
        return LowshelfPrecision.s32;
      case 'f32':
        return LowshelfPrecision.f32;
      case 'f64':
        return LowshelfPrecision.f64;
      default:
        return LowshelfPrecision.auto;
    }
  }
}

/// Values for the `a` option of the `lowshelf` audio filter.
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
  zdf,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case LowshelfTransformType.di:
        return 'di';
      case LowshelfTransformType.dii:
        return 'dii';
      case LowshelfTransformType.tdi:
        return 'tdi';
      case LowshelfTransformType.tdii:
        return 'tdii';
      case LowshelfTransformType.latt:
        return 'latt';
      case LowshelfTransformType.svf:
        return 'svf';
      case LowshelfTransformType.zdf:
        return 'zdf';
    }
  }

  /// Parses a mpv wire string back into a [LowshelfTransformType].
  /// Unknown / empty input falls back to the first member.
  static LowshelfTransformType fromMpv(String? raw) {
    switch (raw) {
      case 'di':
        return LowshelfTransformType.di;
      case 'dii':
        return LowshelfTransformType.dii;
      case 'tdi':
        return LowshelfTransformType.tdi;
      case 'tdii':
        return LowshelfTransformType.tdii;
      case 'latt':
        return LowshelfTransformType.latt;
      case 'svf':
        return LowshelfTransformType.svf;
      case 'zdf':
        return LowshelfTransformType.zdf;
      default:
        return LowshelfTransformType.di;
    }
  }
}

/// Values for the `t` option of the `lowshelf` audio filter.
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
  k,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case LowshelfWidthType.h:
        return 'h';
      case LowshelfWidthType.q:
        return 'q';
      case LowshelfWidthType.o:
        return 'o';
      case LowshelfWidthType.s:
        return 's';
      case LowshelfWidthType.k:
        return 'k';
    }
  }

  /// Parses a mpv wire string back into a [LowshelfWidthType].
  /// Unknown / empty input falls back to the first member.
  static LowshelfWidthType fromMpv(String? raw) {
    switch (raw) {
      case 'h':
        return LowshelfWidthType.h;
      case 'q':
        return LowshelfWidthType.q;
      case 'o':
        return LowshelfWidthType.o;
      case 's':
        return LowshelfWidthType.s;
      case 'k':
        return LowshelfWidthType.k;
      default:
        return LowshelfWidthType.h;
    }
  }
}

/// Values for the `channels` option of the `rubberband` audio filter.
enum RubberbandChannels {
  /// The `apart` option value.
  apart,

  /// The `together` option value.
  together,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case RubberbandChannels.apart:
        return 'apart';
      case RubberbandChannels.together:
        return 'together';
    }
  }

  /// Parses a mpv wire string back into a [RubberbandChannels].
  /// Unknown / empty input falls back to the first member.
  static RubberbandChannels fromMpv(String? raw) {
    switch (raw) {
      case 'apart':
        return RubberbandChannels.apart;
      case 'together':
        return RubberbandChannels.together;
      default:
        return RubberbandChannels.apart;
    }
  }
}

/// Values for the `detector` option of the `rubberband` audio filter.
enum RubberbandDetector {
  /// The `compound` option value.
  compound,

  /// The `percussive` option value.
  percussive,

  /// The `soft` option value.
  soft,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case RubberbandDetector.compound:
        return 'compound';
      case RubberbandDetector.percussive:
        return 'percussive';
      case RubberbandDetector.soft:
        return 'soft';
    }
  }

  /// Parses a mpv wire string back into a [RubberbandDetector].
  /// Unknown / empty input falls back to the first member.
  static RubberbandDetector fromMpv(String? raw) {
    switch (raw) {
      case 'compound':
        return RubberbandDetector.compound;
      case 'percussive':
        return RubberbandDetector.percussive;
      case 'soft':
        return RubberbandDetector.soft;
      default:
        return RubberbandDetector.compound;
    }
  }
}

/// Values for the `formant` option of the `rubberband` audio filter.
enum RubberbandFormant {
  /// The `shifted` option value.
  shifted,

  /// The `preserved` option value.
  preserved,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case RubberbandFormant.shifted:
        return 'shifted';
      case RubberbandFormant.preserved:
        return 'preserved';
    }
  }

  /// Parses a mpv wire string back into a [RubberbandFormant].
  /// Unknown / empty input falls back to the first member.
  static RubberbandFormant fromMpv(String? raw) {
    switch (raw) {
      case 'shifted':
        return RubberbandFormant.shifted;
      case 'preserved':
        return RubberbandFormant.preserved;
      default:
        return RubberbandFormant.shifted;
    }
  }
}

/// Values for the `phase` option of the `rubberband` audio filter.
enum RubberbandPhase {
  /// The `laminar` option value.
  laminar,

  /// The `independent` option value.
  independent,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case RubberbandPhase.laminar:
        return 'laminar';
      case RubberbandPhase.independent:
        return 'independent';
    }
  }

  /// Parses a mpv wire string back into a [RubberbandPhase].
  /// Unknown / empty input falls back to the first member.
  static RubberbandPhase fromMpv(String? raw) {
    switch (raw) {
      case 'laminar':
        return RubberbandPhase.laminar;
      case 'independent':
        return RubberbandPhase.independent;
      default:
        return RubberbandPhase.laminar;
    }
  }
}

/// Values for the `pitchq` option of the `rubberband` audio filter.
enum RubberbandPitch {
  /// The `quality` option value.
  quality,

  /// The `speed` option value.
  speed,

  /// The `consistency` option value.
  consistency,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case RubberbandPitch.quality:
        return 'quality';
      case RubberbandPitch.speed:
        return 'speed';
      case RubberbandPitch.consistency:
        return 'consistency';
    }
  }

  /// Parses a mpv wire string back into a [RubberbandPitch].
  /// Unknown / empty input falls back to the first member.
  static RubberbandPitch fromMpv(String? raw) {
    switch (raw) {
      case 'quality':
        return RubberbandPitch.quality;
      case 'speed':
        return RubberbandPitch.speed;
      case 'consistency':
        return RubberbandPitch.consistency;
      default:
        return RubberbandPitch.quality;
    }
  }
}

/// Values for the `smoothing` option of the `rubberband` audio filter.
enum RubberbandSmoothing {
  /// The `off` option value.
  off,

  /// The `on` option value.
  on_,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case RubberbandSmoothing.off:
        return 'off';
      case RubberbandSmoothing.on_:
        return 'on';
    }
  }

  /// Parses a mpv wire string back into a [RubberbandSmoothing].
  /// Unknown / empty input falls back to the first member.
  static RubberbandSmoothing fromMpv(String? raw) {
    switch (raw) {
      case 'off':
        return RubberbandSmoothing.off;
      case 'on':
        return RubberbandSmoothing.on_;
      default:
        return RubberbandSmoothing.off;
    }
  }
}

/// Values for the `transients` option of the `rubberband` audio filter.
enum RubberbandTransients {
  /// The `crisp` option value.
  crisp,

  /// The `mixed` option value.
  mixed,

  /// The `smooth` option value.
  smooth,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case RubberbandTransients.crisp:
        return 'crisp';
      case RubberbandTransients.mixed:
        return 'mixed';
      case RubberbandTransients.smooth:
        return 'smooth';
    }
  }

  /// Parses a mpv wire string back into a [RubberbandTransients].
  /// Unknown / empty input falls back to the first member.
  static RubberbandTransients fromMpv(String? raw) {
    switch (raw) {
      case 'crisp':
        return RubberbandTransients.crisp;
      case 'mixed':
        return RubberbandTransients.mixed;
      case 'smooth':
        return RubberbandTransients.smooth;
      default:
        return RubberbandTransients.crisp;
    }
  }
}

/// Values for the `window` option of the `rubberband` audio filter.
enum RubberbandWindow {
  /// The `standard` option value.
  standard,

  /// The `short` option value.
  short,

  /// The `long` option value.
  long,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case RubberbandWindow.standard:
        return 'standard';
      case RubberbandWindow.short:
        return 'short';
      case RubberbandWindow.long:
        return 'long';
    }
  }

  /// Parses a mpv wire string back into a [RubberbandWindow].
  /// Unknown / empty input falls back to the first member.
  static RubberbandWindow fromMpv(String? raw) {
    switch (raw) {
      case 'standard':
        return RubberbandWindow.standard;
      case 'short':
        return RubberbandWindow.short;
      case 'long':
        return RubberbandWindow.long;
      default:
        return RubberbandWindow.standard;
    }
  }
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
  dev,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case SilenceremoveDetection.avg:
        return 'avg';
      case SilenceremoveDetection.rms:
        return 'rms';
      case SilenceremoveDetection.peak:
        return 'peak';
      case SilenceremoveDetection.median:
        return 'median';
      case SilenceremoveDetection.ptp:
        return 'ptp';
      case SilenceremoveDetection.dev:
        return 'dev';
    }
  }

  /// Parses a mpv wire string back into a [SilenceremoveDetection].
  /// Unknown / empty input falls back to the first member.
  static SilenceremoveDetection fromMpv(String? raw) {
    switch (raw) {
      case 'avg':
        return SilenceremoveDetection.avg;
      case 'rms':
        return SilenceremoveDetection.rms;
      case 'peak':
        return SilenceremoveDetection.peak;
      case 'median':
        return SilenceremoveDetection.median;
      case 'ptp':
        return SilenceremoveDetection.ptp;
      case 'dev':
        return SilenceremoveDetection.dev;
      default:
        return SilenceremoveDetection.avg;
    }
  }
}

/// Values for the `start_mode` option of the `silenceremove` audio filter.
enum SilenceremoveMode {
  /// The `any` option value.
  any,

  /// The `all` option value.
  all,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case SilenceremoveMode.any:
        return 'any';
      case SilenceremoveMode.all:
        return 'all';
    }
  }

  /// Parses a mpv wire string back into a [SilenceremoveMode].
  /// Unknown / empty input falls back to the first member.
  static SilenceremoveMode fromMpv(String? raw) {
    switch (raw) {
      case 'any':
        return SilenceremoveMode.any;
      case 'all':
        return SilenceremoveMode.all;
      default:
        return SilenceremoveMode.any;
    }
  }
}

/// Values for the `timestamp` option of the `silenceremove` audio filter.
enum SilenceremoveTimestamp {
  /// full timestamps rewrite, keep only the start time
  write,

  /// non-dropped frames are left with same timestamp
  copy,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case SilenceremoveTimestamp.write:
        return 'write';
      case SilenceremoveTimestamp.copy:
        return 'copy';
    }
  }

  /// Parses a mpv wire string back into a [SilenceremoveTimestamp].
  /// Unknown / empty input falls back to the first member.
  static SilenceremoveTimestamp fromMpv(String? raw) {
    switch (raw) {
      case 'write':
        return SilenceremoveTimestamp.write;
      case 'copy':
        return SilenceremoveTimestamp.copy;
      default:
        return SilenceremoveTimestamp.write;
    }
  }
}

/// Values for the `bmode_in` option of the `stereotools` audio filter.
enum StereotoolsBmode {
  /// The `balance` option value.
  balance,

  /// The `amplitude` option value.
  amplitude,

  /// The `power` option value.
  power,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case StereotoolsBmode.balance:
        return 'balance';
      case StereotoolsBmode.amplitude:
        return 'amplitude';
      case StereotoolsBmode.power:
        return 'power';
    }
  }

  /// Parses a mpv wire string back into a [StereotoolsBmode].
  /// Unknown / empty input falls back to the first member.
  static StereotoolsBmode fromMpv(String? raw) {
    switch (raw) {
      case 'balance':
        return StereotoolsBmode.balance;
      case 'amplitude':
        return StereotoolsBmode.amplitude;
      case 'power':
        return StereotoolsBmode.power;
      default:
        return StereotoolsBmode.balance;
    }
  }
}

/// Values for the `mode` option of the `stereotools` audio filter.
enum StereotoolsMode {
  /// The `lr>lr` option value.
  lr_to_lr,

  /// The `lr>ms` option value.
  lr_to_ms,

  /// The `ms>lr` option value.
  ms_to_lr,

  /// The `lr>ll` option value.
  lr_to_ll,

  /// The `lr>rr` option value.
  lr_to_rr,

  /// The `lr>l+r` option value.
  lr_to_l_plus_r,

  /// The `lr>rl` option value.
  lr_to_rl,

  /// The `ms>ll` option value.
  ms_to_ll,

  /// The `ms>rr` option value.
  ms_to_rr,

  /// The `ms>rl` option value.
  ms_to_rl,

  /// The `lr>l-r` option value.
  lr_to_l_minus_r,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case StereotoolsMode.lr_to_lr:
        return 'lr>lr';
      case StereotoolsMode.lr_to_ms:
        return 'lr>ms';
      case StereotoolsMode.ms_to_lr:
        return 'ms>lr';
      case StereotoolsMode.lr_to_ll:
        return 'lr>ll';
      case StereotoolsMode.lr_to_rr:
        return 'lr>rr';
      case StereotoolsMode.lr_to_l_plus_r:
        return 'lr>l+r';
      case StereotoolsMode.lr_to_rl:
        return 'lr>rl';
      case StereotoolsMode.ms_to_ll:
        return 'ms>ll';
      case StereotoolsMode.ms_to_rr:
        return 'ms>rr';
      case StereotoolsMode.ms_to_rl:
        return 'ms>rl';
      case StereotoolsMode.lr_to_l_minus_r:
        return 'lr>l-r';
    }
  }

  /// Parses a mpv wire string back into a [StereotoolsMode].
  /// Unknown / empty input falls back to the first member.
  static StereotoolsMode fromMpv(String? raw) {
    switch (raw) {
      case 'lr>lr':
        return StereotoolsMode.lr_to_lr;
      case 'lr>ms':
        return StereotoolsMode.lr_to_ms;
      case 'ms>lr':
        return StereotoolsMode.ms_to_lr;
      case 'lr>ll':
        return StereotoolsMode.lr_to_ll;
      case 'lr>rr':
        return StereotoolsMode.lr_to_rr;
      case 'lr>l+r':
        return StereotoolsMode.lr_to_l_plus_r;
      case 'lr>rl':
        return StereotoolsMode.lr_to_rl;
      case 'ms>ll':
        return StereotoolsMode.ms_to_ll;
      case 'ms>rr':
        return StereotoolsMode.ms_to_rr;
      case 'ms>rl':
        return StereotoolsMode.ms_to_rl;
      case 'lr>l-r':
        return StereotoolsMode.lr_to_l_minus_r;
      default:
        return StereotoolsMode.lr_to_lr;
    }
  }
}

/// Values for the `lfe_mode` option of the `surround` audio filter.
enum SurroundLfeMode {
  /// just add LFE channel
  add,

  /// subtract LFE channel with others
  sub,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case SurroundLfeMode.add:
        return 'add';
      case SurroundLfeMode.sub:
        return 'sub';
    }
  }

  /// Parses a mpv wire string back into a [SurroundLfeMode].
  /// Unknown / empty input falls back to the first member.
  static SurroundLfeMode fromMpv(String? raw) {
    switch (raw) {
      case 'add':
        return SurroundLfeMode.add;
      case 'sub':
        return SurroundLfeMode.sub;
      default:
        return SurroundLfeMode.add;
    }
  }
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
  kaiser,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case SurroundWinFunc.rect:
        return 'rect';
      case SurroundWinFunc.bartlett:
        return 'bartlett';
      case SurroundWinFunc.hann:
        return 'hann';
      case SurroundWinFunc.hanning:
        return 'hanning';
      case SurroundWinFunc.hamming:
        return 'hamming';
      case SurroundWinFunc.blackman:
        return 'blackman';
      case SurroundWinFunc.welch:
        return 'welch';
      case SurroundWinFunc.flattop:
        return 'flattop';
      case SurroundWinFunc.bharris:
        return 'bharris';
      case SurroundWinFunc.bnuttall:
        return 'bnuttall';
      case SurroundWinFunc.bhann:
        return 'bhann';
      case SurroundWinFunc.sine:
        return 'sine';
      case SurroundWinFunc.nuttall:
        return 'nuttall';
      case SurroundWinFunc.lanczos:
        return 'lanczos';
      case SurroundWinFunc.gauss:
        return 'gauss';
      case SurroundWinFunc.tukey:
        return 'tukey';
      case SurroundWinFunc.dolph:
        return 'dolph';
      case SurroundWinFunc.cauchy:
        return 'cauchy';
      case SurroundWinFunc.parzen:
        return 'parzen';
      case SurroundWinFunc.poisson:
        return 'poisson';
      case SurroundWinFunc.bohman:
        return 'bohman';
      case SurroundWinFunc.kaiser:
        return 'kaiser';
    }
  }

  /// Parses a mpv wire string back into a [SurroundWinFunc].
  /// Unknown / empty input falls back to the first member.
  static SurroundWinFunc fromMpv(String? raw) {
    switch (raw) {
      case 'rect':
        return SurroundWinFunc.rect;
      case 'bartlett':
        return SurroundWinFunc.bartlett;
      case 'hann':
        return SurroundWinFunc.hann;
      case 'hanning':
        return SurroundWinFunc.hanning;
      case 'hamming':
        return SurroundWinFunc.hamming;
      case 'blackman':
        return SurroundWinFunc.blackman;
      case 'welch':
        return SurroundWinFunc.welch;
      case 'flattop':
        return SurroundWinFunc.flattop;
      case 'bharris':
        return SurroundWinFunc.bharris;
      case 'bnuttall':
        return SurroundWinFunc.bnuttall;
      case 'bhann':
        return SurroundWinFunc.bhann;
      case 'sine':
        return SurroundWinFunc.sine;
      case 'nuttall':
        return SurroundWinFunc.nuttall;
      case 'lanczos':
        return SurroundWinFunc.lanczos;
      case 'gauss':
        return SurroundWinFunc.gauss;
      case 'tukey':
        return SurroundWinFunc.tukey;
      case 'dolph':
        return SurroundWinFunc.dolph;
      case 'cauchy':
        return SurroundWinFunc.cauchy;
      case 'parzen':
        return SurroundWinFunc.parzen;
      case 'poisson':
        return SurroundWinFunc.poisson;
      case 'bohman':
        return SurroundWinFunc.bohman;
      case 'kaiser':
        return SurroundWinFunc.kaiser;
      default:
        return SurroundWinFunc.rect;
    }
  }
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
  f64,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case TiltshelfPrecision.auto:
        return 'auto';
      case TiltshelfPrecision.s16:
        return 's16';
      case TiltshelfPrecision.s32:
        return 's32';
      case TiltshelfPrecision.f32:
        return 'f32';
      case TiltshelfPrecision.f64:
        return 'f64';
    }
  }

  /// Parses a mpv wire string back into a [TiltshelfPrecision].
  /// Unknown / empty input falls back to the first member.
  static TiltshelfPrecision fromMpv(String? raw) {
    switch (raw) {
      case 'auto':
        return TiltshelfPrecision.auto;
      case 's16':
        return TiltshelfPrecision.s16;
      case 's32':
        return TiltshelfPrecision.s32;
      case 'f32':
        return TiltshelfPrecision.f32;
      case 'f64':
        return TiltshelfPrecision.f64;
      default:
        return TiltshelfPrecision.auto;
    }
  }
}

/// Values for the `a` option of the `tiltshelf` audio filter.
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
  zdf,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case TiltshelfTransformType.di:
        return 'di';
      case TiltshelfTransformType.dii:
        return 'dii';
      case TiltshelfTransformType.tdi:
        return 'tdi';
      case TiltshelfTransformType.tdii:
        return 'tdii';
      case TiltshelfTransformType.latt:
        return 'latt';
      case TiltshelfTransformType.svf:
        return 'svf';
      case TiltshelfTransformType.zdf:
        return 'zdf';
    }
  }

  /// Parses a mpv wire string back into a [TiltshelfTransformType].
  /// Unknown / empty input falls back to the first member.
  static TiltshelfTransformType fromMpv(String? raw) {
    switch (raw) {
      case 'di':
        return TiltshelfTransformType.di;
      case 'dii':
        return TiltshelfTransformType.dii;
      case 'tdi':
        return TiltshelfTransformType.tdi;
      case 'tdii':
        return TiltshelfTransformType.tdii;
      case 'latt':
        return TiltshelfTransformType.latt;
      case 'svf':
        return TiltshelfTransformType.svf;
      case 'zdf':
        return TiltshelfTransformType.zdf;
      default:
        return TiltshelfTransformType.di;
    }
  }
}

/// Values for the `t` option of the `tiltshelf` audio filter.
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
  k,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case TiltshelfWidthType.h:
        return 'h';
      case TiltshelfWidthType.q:
        return 'q';
      case TiltshelfWidthType.o:
        return 'o';
      case TiltshelfWidthType.s:
        return 's';
      case TiltshelfWidthType.k:
        return 'k';
    }
  }

  /// Parses a mpv wire string back into a [TiltshelfWidthType].
  /// Unknown / empty input falls back to the first member.
  static TiltshelfWidthType fromMpv(String? raw) {
    switch (raw) {
      case 'h':
        return TiltshelfWidthType.h;
      case 'q':
        return TiltshelfWidthType.q;
      case 'o':
        return TiltshelfWidthType.o;
      case 's':
        return TiltshelfWidthType.s;
      case 'k':
        return TiltshelfWidthType.k;
      default:
        return TiltshelfWidthType.h;
    }
  }
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
  f64,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case TreblePrecision.auto:
        return 'auto';
      case TreblePrecision.s16:
        return 's16';
      case TreblePrecision.s32:
        return 's32';
      case TreblePrecision.f32:
        return 'f32';
      case TreblePrecision.f64:
        return 'f64';
    }
  }

  /// Parses a mpv wire string back into a [TreblePrecision].
  /// Unknown / empty input falls back to the first member.
  static TreblePrecision fromMpv(String? raw) {
    switch (raw) {
      case 'auto':
        return TreblePrecision.auto;
      case 's16':
        return TreblePrecision.s16;
      case 's32':
        return TreblePrecision.s32;
      case 'f32':
        return TreblePrecision.f32;
      case 'f64':
        return TreblePrecision.f64;
      default:
        return TreblePrecision.auto;
    }
  }
}

/// Values for the `a` option of the `treble` audio filter.
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
  zdf,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case TrebleTransformType.di:
        return 'di';
      case TrebleTransformType.dii:
        return 'dii';
      case TrebleTransformType.tdi:
        return 'tdi';
      case TrebleTransformType.tdii:
        return 'tdii';
      case TrebleTransformType.latt:
        return 'latt';
      case TrebleTransformType.svf:
        return 'svf';
      case TrebleTransformType.zdf:
        return 'zdf';
    }
  }

  /// Parses a mpv wire string back into a [TrebleTransformType].
  /// Unknown / empty input falls back to the first member.
  static TrebleTransformType fromMpv(String? raw) {
    switch (raw) {
      case 'di':
        return TrebleTransformType.di;
      case 'dii':
        return TrebleTransformType.dii;
      case 'tdi':
        return TrebleTransformType.tdi;
      case 'tdii':
        return TrebleTransformType.tdii;
      case 'latt':
        return TrebleTransformType.latt;
      case 'svf':
        return TrebleTransformType.svf;
      case 'zdf':
        return TrebleTransformType.zdf;
      default:
        return TrebleTransformType.di;
    }
  }
}

/// Values for the `t` option of the `treble` audio filter.
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
  k,
  ;

  /// Wire-side string consumed by mpv.
  String get mpvValue {
    switch (this) {
      case TrebleWidthType.h:
        return 'h';
      case TrebleWidthType.q:
        return 'q';
      case TrebleWidthType.o:
        return 'o';
      case TrebleWidthType.s:
        return 's';
      case TrebleWidthType.k:
        return 'k';
    }
  }

  /// Parses a mpv wire string back into a [TrebleWidthType].
  /// Unknown / empty input falls back to the first member.
  static TrebleWidthType fromMpv(String? raw) {
    switch (raw) {
      case 'h':
        return TrebleWidthType.h;
      case 'q':
        return TrebleWidthType.q;
      case 'o':
        return TrebleWidthType.o;
      case 's':
        return TrebleWidthType.s;
      case 'k':
        return TrebleWidthType.k;
      default:
        return TrebleWidthType.h;
    }
  }
}

/// Identifies a single typed audio filter from the
/// [AudioEffects] bundle.
///
/// One value per filter on the AUDIO_FILTERS whitelist —
/// the same set surfaced as `*Settings` fields on
/// [AudioEffects]. Use it as a typed identifier in APIs
/// that pick a single filter slot, e.g.
/// `player.stream.tap(AudioEffect.equalizer, side: TapSide.post)`.
enum AudioEffect {
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

  /// The `rubberband` audio filter.
  rubberband,

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
  virtualbass,
  ;

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
