// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

// The `Media.fromBlob` side of platforms without browser files.

/// No browser file outside the web: throws [UnsupportedError].
(String, String?) blobUrl(Object blob) => throw UnsupportedError(
  'Media.fromBlob takes a File or Blob of the browser, on the web; '
  'elsewhere open a file by its path',
);
