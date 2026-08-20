import Quickshell

// Standalone development harness.
//
// Deliberately NOT an installed plugin yet. An installed plugin shares the
// shell's single long-running process, so every edit means bouncing the whole
// bar; standalone restarts in about a second. More importantly for this
// plugin: a crash here cannot take the user's shell down with it, and while
// the lock lifecycle is still unproven that separation is worth having.
//
// This lives at the project root rather than under dev/ because Quickshell
// refuses to load QML modules from outside the config folder, and the config
// folder is this file's own directory. From dev/, `import ".."` is rejected.
ShellRoot {
  Service {}
}
