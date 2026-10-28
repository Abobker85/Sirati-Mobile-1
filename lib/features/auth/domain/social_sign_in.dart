/// Whether third-party sign-in (Google / Apple) is offered on the login
/// screen.
///
/// On for the design while the providers are being wired: the buttons only
/// show a "coming soon" notice for now. Turn it off for any store build
/// that ships before they work end to end: review rejects controls that
/// don't work (App Store 2.1), and offering Google sign-in makes Sign in
/// with Apple mandatory (App Store 4.8).
const socialSignInEnabled = true;
