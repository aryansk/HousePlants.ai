/// Release configuration that is safe to compile into the app.
///
/// No third-party credentials belong in this target: anything compiled into an IPA can be
/// extracted. Plant identification uses the user's own Pl@ntNet key from the Keychain until
/// a server-side proxy is introduced.
enum ProConfig {}
