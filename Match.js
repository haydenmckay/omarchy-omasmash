.pragma library

// Longest suffix of `buffer` that is also a prefix of `passphrase`.
//
// Shared by Service.qml (which owns the real unlock) and the dev previews
// (which only need the hint to fill in). Extracted so the two cannot drift --
// a preview that scores progress differently from the service would be worse
// than no preview, because it would look correct while lying.
//
// Falling back to the longest still-valid prefix, rather than resetting to
// zero on a wrong key, is what lets a parent mash between correct letters
// without losing their place: "omom" leaves you two in, not out.
function progress(buffer, passphrase) {
  var pass = String(passphrase || "").toLowerCase()
  var buf = String(buffer || "").toLowerCase()
  var max = Math.min(pass.length, buf.length)
  for (var k = max; k > 0; k--) {
    if (buf.slice(-k) === pass.slice(0, k)) return k
  }
  return 0
}
