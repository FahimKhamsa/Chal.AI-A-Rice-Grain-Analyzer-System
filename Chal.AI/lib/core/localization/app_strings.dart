import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/language_provider.dart';

class AppStrings {
  final String lang;
  const AppStrings(this.lang);

  bool get isBn => lang == 'bn';

  // ── General ──────────────────────────────────────────────────────────────
  String get appName => 'Chal.AI';
  String get appTagline => isBn
      ? 'AI-চালিত চালের গুণগত মান বিশ্লেষণ'
      : 'AI-Powered Rice Grain Analysis';
  String get cancel => isBn ? 'বাতিল' : 'Cancel';
  String get retry => isBn ? 'পুনরায় চেষ্টা করুন' : 'Retry';
  String get delete => isBn ? 'মুছে ফেলুন' : 'Delete';
  String get save => isBn ? 'সংরক্ষণ করুন' : 'Save';
  String get edit => isBn ? 'সম্পাদনা করুন' : 'Edit';
  String get version => isBn ? 'সংস্করণ' : 'Version';
  String get email => isBn ? 'ইমেইল' : 'Email';
  String get password => isBn ? 'পাসওয়ার্ড' : 'Password';
  String get emailPlaceholder => 'you@example.com';
  String get passwordPlaceholder => '••••••••';
  String get somethingWentWrong => isBn
      ? 'কোথাও কোনো সমস্যা হয়েছে। অনুগ্রহ করে আবার চেষ্টা করুন।'
      : 'Something went wrong. Please try again.';
  String get networkError => isBn
      ? 'নেটওয়ার্ক সমস্যা। আপনার ইন্টারনেট সংযোগ পরীক্ষা করুন।'
      : 'Network error. Please check your connection.';

  // ── Language toggle ───────────────────────────────────────────────────────
  String get language => isBn ? 'ভাষা' : 'Language';
  String get langEn => 'EN';
  String get langBn => 'বাং';

  // ── Capture screen ────────────────────────────────────────────────────────
  String get tapToCapture => isBn ? 'ছবি তুলতে ট্যাপ করুন' : 'Tap to capture';
  String get photoAnalyzedByAi => isBn
      ? 'AI-এর মাধ্যমে ছবিটি বিশ্লেষণ করা হবে'
      : 'Photo will be analyzed by AI';
  String get retake => isBn ? 'পুনরায় তুলুন' : 'Retake';
  String get batchName => isBn ? 'ব্যাচের নাম' : 'Batch name';
  String get batchNameHint =>
      isBn ? 'যেমন: ব্যাচ এ, মাঠ ৩' : 'e.g. Batch A, Field 3';
  String get fromGallery => isBn ? 'গ্যালারি থেকে' : 'From Gallery';
  String get runDemo => isBn ? 'ডেমো চালান' : 'Run Demo';
  String get captureTip => isBn
      ? 'সেরা ফলাফলের জন্য, পর্যাপ্ত আলোতে কালো কোনো পৃষ্ঠের ওপর চালের দানাগুলো রাখুন।'
      : 'For best results, place grains on a black surface in good natural light.';
  String get couldNotSaveRecord =>
      isBn ? 'রেকর্ড সংরক্ষণ করা যায়নি' : 'Could not save record';
  String get batchADefault => isBn ? 'ব্যাচ এ' : 'Batch A';
  String get startAnalysis => isBn ? 'বিশ্লেষণ শুরু করুন' : 'Start Analysis';
  String get uploadImageToStart => isBn
      ? 'বিশ্লেষণ শুরু করতে ছবি যোগ করুন'
      : 'Upload an image to start analysis';

  // ── Settings screen ───────────────────────────────────────────────────────
  String get settings => isBn ? 'সেটিংস' : 'Settings';
  String get about => isBn ? 'পরিচিতি' : 'About';
  String get appearance => isBn ? 'ডিসপ্লে ও থিম' : 'Appearance';
  String get theme => isBn ? 'থিম' : 'Theme';

  // ── Login screen ──────────────────────────────────────────────────────────
  String get signInToContinue =>
      isBn ? 'চালিয়ে যেতে সাইন ইন করুন' : 'Sign in to continue';
  String get signIn => isBn ? 'সাইন ইন' : 'Sign In';
  String get forgotPassword =>
      isBn ? 'পাসওয়ার্ড ভুলে গেছেন?' : 'Forgot password?';
  String get dontHaveAccount =>
      isBn ? 'অ্যাকাউন্ট নেই?' : "Don't have an account?";
  String get signUp => isBn ? 'সাইন আপ' : 'Sign Up';
  String get enterEmailAndPassword => isBn
      ? 'অনুগ্রহ করে ইমেইল এবং পাসওয়ার্ড দিন।'
      : 'Please enter your email and password.';
  String get invalidEmailOrPassword =>
      isBn ? 'ইমেইল অথবা পাসওয়ার্ডটি ভুল।' : 'Invalid email or password.';

  // ── Signup screen ─────────────────────────────────────────────────────────
  String get createAccount => isBn ? 'অ্যাকাউন্ট তৈরি করুন' : 'Create Account';
  String get signupSubtitle => isBn
      ? 'আপনার বিশ্লেষণগুলো সংরক্ষণ করতে Chal.AI-তে যোগ দিন'
      : 'Join Chal.AI to save your analyses';
  String get confirmPassword =>
      isBn ? 'পাসওয়ার্ড নিশ্চিত করুন' : 'Confirm Password';
  String get fillAllFields =>
      isBn ? 'অনুগ্রহ করে সব তথ্য পূরণ করুন।' : 'Please fill in all fields.';
  String get passwordsDoNotMatch =>
      isBn ? 'পাসওয়ার্ড দুটি মেলেনি।' : 'Passwords do not match.';
  String get passwordTooShort => isBn
      ? 'পাসওয়ার্ডটি কমপক্ষে ৬ অক্ষরের হতে হবে।'
      : 'Password must be at least 6 characters.';
  String get emailAlreadyRegistered => isBn
      ? 'এই ইমেইলটি ইতিমধ্যে নিবন্ধিত। সাইন ইন করার চেষ্টা করুন।'
      : 'This email is already registered. Try signing in instead.';
  String get checkYourEmail =>
      isBn ? 'আপনার ইমেইল চেক করুন' : 'Check Your Email';
  String get verificationLinkSent => isBn
      ? 'একটি ভেরিফিকেশন লিঙ্ক পাঠানো হয়েছে'
      : 'We sent a verification link to';
  String get tapLinkToContinue => isBn
      ? 'চালিয়ে যেতে আপনার ইনবক্সের লিঙ্কে ট্যাপ করুন।'
      : 'Tap the link in your inbox to continue.';
  String get waitingForConfirmation =>
      isBn ? 'নিশ্চিতকরণের অপেক্ষায়…' : 'Waiting for confirmation…';
  String get alreadyHaveAccount =>
      isBn ? 'ইতিমধ্যে অ্যাকাউন্ট আছে?' : 'Already have an account?';

  // ── Forgot password screen ────────────────────────────────────────────────
  String get resetYourPassword =>
      isBn ? 'পাসওয়ার্ড রিসেট করুন' : 'Reset your password';
  String get forgotPasswordSubtitle => isBn
      ? 'আপনার ইমেইল ঠিকানাটি দিন, আমরা একটি রিসেট লিংক পাঠিয়ে দেব।'
      : "Enter your email and we'll send you a link to reset your password.";
  String get enterEmailAddress => isBn
      ? 'অনুগ্রহ করে ইমেইল ঠিকানা দিন।'
      : 'Please enter your email address.';
  String get couldNotSendResetEmail => isBn
      ? 'রিসেট ইমেইল পাঠানো যায়নি। আবার চেষ্টা করুন।'
      : 'Could not send reset email. Please try again.';
  String get sendResetLink => isBn ? 'রিসেট লিঙ্ক পাঠান' : 'Send reset link';
  String get checkYourInbox => isBn ? 'আপনার ইনবক্স দেখুন' : 'Check your inbox';
  String get resetLinkSentTo => isBn
      ? 'পাসওয়ার্ড রিসেট লিঙ্ক পাঠানো হয়েছে'
      : "We've sent a password reset link to";
  String get backToLogin => isBn ? 'লগইনে ফিরুন' : 'Back to Login';

  // ── Reset password screen ─────────────────────────────────────────────────
  String get setNewPassword =>
      isBn ? 'নতুন পাসওয়ার্ড সেট করুন' : 'Set New Password';
  String get chooseNewPassword => isBn
      ? 'আপনার অ্যাকাউন্টের জন্য একটি নতুন পাসওয়ার্ড বেছে নিন।'
      : 'Choose a new password for your account.';
  String get newPassword => isBn ? 'নতুন পাসওয়ার্ড' : 'New password';
  String get confirmNewPassword =>
      isBn ? 'নতুন পাসওয়ার্ড নিশ্চিত করুন' : 'Confirm new password';
  String get couldNotUpdatePassword => isBn
      ? 'পাসওয়ার্ড আপডেট করা যায়নি। আবার চেষ্টা করুন।'
      : 'Could not update password. Please try again.';
  String get updatePassword =>
      isBn ? 'পাসওয়ার্ড আপডেট করুন' : 'Update Password';

  // ── Profile setup screen ──────────────────────────────────────────────────
  String get completeYourProfile =>
      isBn ? 'আপনার প্রোফাইল সম্পূর্ণ করুন' : 'Complete Your Profile';
  String get tellUsAboutYourself =>
      isBn ? 'আপনার সম্পর্কে কিছু তথ্য দিন' : 'Tell us a little about yourself';
  String get firstName => isBn ? 'প্রথম নাম' : 'First Name';
  String get firstNameHint => isBn ? 'রহিম' : 'John';
  String get lastName => isBn ? 'শেষ নাম' : 'Last Name';
  String get lastNameHint => isBn ? 'হোসেন' : 'Doe';
  String get phoneNumber => isBn ? 'ফোন নম্বর' : 'Phone Number';
  String get phoneHint => '+880 1XXX XXX XXX';
  String get location => isBn ? 'অবস্থান' : 'Location';
  String get locationHint => isBn ? 'শহর, দেশ' : 'City, Country';
  String get designation => isBn ? 'পদবী (ঐচ্ছিক)' : 'Designation (Optional)';
  String get designationHint =>
      isBn ? 'যেমন: কৃষক, গবেষক' : 'e.g. Farmer, Researcher';
  String get fillRequiredFields => isBn
      ? 'সব প্রয়োজনীয় তথ্য পূরণ করুন।'
      : 'Please fill in all required fields.';
  String get continueBtn => isBn ? 'চালিয়ে যান' : 'Continue';

  // ── Profile screen ────────────────────────────────────────────────────────
  String get profile => isBn ? 'প্রোফাইল' : 'Profile';
  String get phone => isBn ? 'ফোন' : 'Phone';
  String get optional => isBn ? 'ঐচ্ছিক' : 'Optional';
  String get profileUpdated =>
      isBn ? 'প্রোফাইল আপডেট করা হয়েছে' : 'Profile updated';
  String get failedToSave => isBn
      ? 'সংরক্ষণ করা যায়নি। আবার চেষ্টা করুন।'
      : 'Failed to save. Please try again.';
  String get failedToLoadProfile =>
      isBn ? 'প্রোফাইল লোড করা যায়নি' : 'Failed to load profile';

  // ── Analysis result screen ────────────────────────────────────────────────
  String get integrityScore => isBn ? 'গুণগত মান স্কোর' : 'Integrity Score';
  String get excellentQuality => isBn ? '⭐ চমৎকার মান' : '⭐ Excellent Quality';
  String get goodQuality => isBn ? '✅ ভালো মান' : '✅ Good Quality';
  String get fairQuality => isBn ? '⚠️ মোটামুটি মান' : '⚠️ Fair Quality';
  String get poorQuality => isBn ? '❌ নিম্ন মানের' : '❌ Poor Quality';
  String get varietyDetected => isBn ? 'শনাক্তকৃত জাত' : 'VARIETY DETECTED';
  String get confidence => isBn ? 'নিশ্চয়তা' : 'confidence';
  String get grainBreakdown => isBn ? 'দানা বিশ্লেষণ' : 'GRAIN BREAKDOWN';
  String get healthy => isBn ? 'অক্ষত দানা' : 'Healthy';
  String get threeQuarterBroken => isBn ? '৩/৪ অংশ ভাঙা দানা' : '¾ Broken';
  String get halfBroken => isBn ? 'অর্ধেক ভাঙা দানা' : 'Half Broken';
  String get impurity => isBn ? 'অপদ্রব্য/ময়লা' : 'Impurity';
  String get discolored => isBn ? 'বিবর্ণ দানা' : 'Discolored';
  String get totalGrains => isBn ? 'মোট দানা' : 'Total Grains';
  String get processedIn => isBn ? 'প্রসেসিং সময়' : 'Processed In';
  String get analyzedOn => isBn ? 'বিশ্লেষণের তারিখ' : 'Analyzed On';
  String get viewFullReport =>
      isBn ? 'পূর্ণাঙ্গ রিপোর্ট দেখুন' : 'View Full Report';
  String get view => isBn ? 'দেখুন' : 'View';
  String get download => isBn ? 'ডাউনলোড' : 'Download';
  String get saving => isBn ? 'সংরক্ষণ হচ্ছে…' : 'Saving…';

  // ── Detailed report screen ────────────────────────────────────────────────
  String get fullReport => isBn ? 'পূর্ণাঙ্গ রিপোর্ট' : 'Full Report';
  String get grainBreakdownTab => isBn ? 'দানার বিবরণ' : 'Grain Breakdown';
  String get imagesTab => isBn ? 'ছবি' : 'Images';
  String get score => isBn ? 'স্কোর' : 'Score';
  String get grainBreakdownTitle => isBn ? 'দানার বিবরণ' : 'Grain Breakdown';
  String get distributionAcross =>
      isBn ? 'শনাক্তকৃত দানার অনুপাত' : 'Distribution across';
  String get detectedGrains => isBn ? 'টি শনাক্তকৃত দানা' : 'detected grains';
  String get noGrainsDetected =>
      isBn ? 'কোনো চালের দানা শনাক্ত হয়নি' : 'No grains detected';
  String get grains => isBn ? 'টি দানা' : 'grains';
  String get ofTotal => isBn ? 'মোটের' : '% of total';
  String get annotatedImages => isBn ? 'চিহ্নিত ছবিসমূহ' : 'Annotated Images';
  String get aiGeneratedOverlays => isBn
      ? 'AI-দ্বারা তৈরি বিশ্লেষণ ওভারলে'
      : 'AI-generated grain analysis overlays';
  String get morphologyAnalysis =>
      isBn ? 'আকৃতি বিশ্লেষণ' : 'Morphology Analysis';
  String get morphologySubtitle => isBn
      ? 'আকার ও রঙের ওপর ভিত্তি করে বাউন্ডিং বক্স'
      : 'Bounding boxes colored by grain size & discoloration';
  String get colorAnalysis => isBn ? 'রঙ বিশ্লেষণ' : 'Color Analysis';
  String get colorSubtitle => isBn
      ? 'HSV-ভিত্তিক বিবর্ণতা শনাক্তকরণ ওভারলে'
      : 'HSV-based discoloration detection overlay';
  String get noAnnotatedImages =>
      isBn ? 'কোনো চিহ্নিত ছবি উপলব্ধ নেই' : 'No annotated images available';
  String get expand => isBn ? 'বড় করুন' : 'Expand';
  String get share => isBn ? 'শেয়ার করুন' : 'Share';
  String get exportPdf => isBn ? 'PDF এক্সপোর্ট' : 'Export PDF';
  String get reportHeader =>
      isBn ? 'Chal.AI বিশ্লেষণ রিপোর্ট' : 'Chal.AI Analysis Report';
  String get batch => isBn ? 'ব্যাচ' : 'Batch';
  String get date => isBn ? 'তারিখ' : 'Date';
  String get processingTime => isBn ? 'প্রসেসিং সময়' : 'Processing Time';
  String get generatedBy =>
      isBn ? 'Chal.AI দ্বারা তৈরি 🌾' : 'Generated by Chal.AI 🌾';
  String get seconds => isBn ? 'সেকেন্ড' : 's';
  String get grainsSuffix => isBn ? 'টি দানা' : ' Grains';

  // ── History screen ────────────────────────────────────────────────────────
  String get analysisHistory => isBn ? 'বিশ্লেষণের ইতিহাস' : 'Analysis History';
  String get failedToLoadHistory =>
      isBn ? 'ইতিহাস লোড করা যায়নি' : 'Failed to load history';
  String get noAnalysesYet =>
      isBn ? 'এখনো কোনো বিশ্লেষণ করা হয়নি' : 'No analyses yet';
  String get savedAnalysesWillAppear => isBn
      ? 'আপনার সংরক্ষিত বিশ্লেষণগুলো এখানে দেখা যাবে'
      : 'Your saved analyses will appear here';
  String get unknownVariety => isBn ? 'অজানা জাত' : 'Unknown variety';
  String get deleteRecord => isBn ? 'রেকর্ডটি মুছে ফেলবেন?' : 'Delete record?';
  String get deleteConfirmMessage => isBn
      ? 'এই বিশ্লেষণটি স্থায়ীভাবে মুছে যাবে।'
      : 'This analysis will be permanently removed.';

  // ── Sidebar ───────────────────────────────────────────────────────────────
  String get home => isBn ? 'হোম' : 'Home';
  String get history => isBn ? 'ইতিহাস' : 'History';
  String get signOut => isBn ? 'সাইন আউট' : 'Sign Out';
  String get signOutConfirmTitle => isBn ? 'সাইন আউট করবেন?' : 'Sign out?';
  String get signOutConfirmMessage => isBn
      ? 'আপনি কি নিশ্চিতভাবে সাইন আউট করতে চান?'
      : 'Are you sure you want to sign out?';
}

final appStringsProvider = Provider<AppStrings>((ref) {
  return AppStrings(ref.watch(languageProvider));
});
