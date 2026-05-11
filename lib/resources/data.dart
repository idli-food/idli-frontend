class AppData {
  // App
  static const String appTitle = 'idli';

  // Splash
  static const String splashTagline = 'Getting things ready';
  static const String splashSubtitle = 'Good food takes time';

  // Welcome
  static const String welcomeTagline = 'Your food. Your story.';
  static const String welcomeRegister = 'Create Account';
  static const String welcomeLogin = 'Log In';

  // Phone
  static const String phoneTitle = "What's your\nnumber?";
  static const String phoneSubtitle = "We'll send you a verification code";
  static const String phoneSendOtp = 'Send OTP';
  static const String phoneErrorEmpty = 'Please enter your phone number';
  static const String phoneErrorInvalid = 'Enter a valid 10-digit mobile number';

  // OTP
  static const String otpTitle = 'Enter verification\ncode';
  static const String otpResendIn = 'Resend in ';
  static const String otpResend = 'Resend OTP';
  static const String otpVerify = 'Verify';

  // Profile
  static const String profileTitle = 'Complete your\nprofile';
  static const String profileSubtitle = 'Help us personalise your feed';
  static const String profilePhotoHint = 'Add photo';
  static const String profileUsername = 'Username';
  static const String profileUsernameHint = 'e.g. foodie_anu';
  static const String profileFullName = 'Full Name';
  static const String profileFullNameHint = 'Your name';
  static const String profileDob = 'Date of Birth';
  static const String profileDobHint = 'DD / MM / YYYY';
  static const String profileBio = 'Bio';
  static const String profileBioHint = 'Tell us about your food journey… (optional)';
  static const String profileFoodType = 'Food Preference';
  static const String profileVeg = 'Veg';
  static const String profileNonVeg = 'Non Veg';
  static const String profileCuisines = 'Favourite Cuisines';
  static const String profileCuisinesHint = 'Pick at least one';
  static const String profileLocation = 'Your Location';
  static const String profileLocationHint = 'e.g. Indiranagar, Bengaluru';
  static const String profileComplete = 'Complete Profile';

  // Profile validation
  static const String profileErrorUsername = 'Username is required';
  static const String profileErrorUsernameFormat =
      'Letters, numbers, underscores only · 3–20 chars · must start with a letter';
  static const String profileErrorFullName = 'Full name is required';
  static const String profileErrorDob = 'Date of birth is required';
  static const String profileErrorDobAge = 'You must be at least 13 years old';
  static const String profileErrorFoodType = 'Please select Veg or Non Veg';
  static const String profileErrorCuisines = 'Please select at least one cuisine';
  static const String profileErrorLocation = 'Location is required';

  // Location picker
  static const String locationTitle = 'Set your location';
  static const String locationSearchHint = 'Search area or street name…';
  static const String locationConfirm = 'Confirm Location';
  static const String locationPinHint = 'Move the map to pin your location';

  // Nav bar
  static const String navHome = 'Home';
  static const String navExplore = 'Explore';
  static const String navSaved = 'Saved';
  static const String navProfile = 'Profile';

  // Profile screen
  static const String profileUserName = 'Aravind BL';
  static const String profileHandle = '@aravind.eats';
  static const String profileBioText =
      'Contrary to popular belief, Lorem ipsum is not simply random text. '
      'It has roots in a piece of';
  static const String profileLocationText = 'Thiruvananthapuram, Kerala';
  static const String profilePostsCount = '128';
  static const String profileLikesCount = '1.2M';
  static const String profileStarsCount = '244k';
  static const String profileRatingValue = '4.9';
  static const String profilePostsLabel = 'Posts';
  static const String profileLikesLabel = 'Likes';
  static const String profileStarsLabel = 'Stars';
  static const String profileRatingLabel = 'rating';
  static const String profileEditBtn = 'Edit Profile';
  static const String profileShareBtn = 'Share Profile';
  static const String profileLogoutBtn = 'Logout';
  static const String profileNewHighlight = 'New';
  static const List<Map<String, String>> profileHighlights = [
    {'emoji': '🍗', 'name': 'Butter Chicken'},
    {'emoji': '🌊', 'name': 'Kollam'},
    {'emoji': '🥗', 'name': 'Top Veg'},
    {'emoji': '🍖', 'name': 'Mandi'},
    {'emoji': '🐟', 'name': 'Fish curry'},
  ];

  // Saved screen
  static const String savedTitle = 'Saved';
  static const String savedSubtitle = '128 posts saved';
  static const List<String> savedFilters = ['All', 'Dishes', 'Restaurants', 'Places'];

  // Explore
  static const String exploreSearchHint = 'Search for your favourite food';
  static const String exploreSearchByPlace = 'Search by Place';

  // Create Post
  static const String createPostTitle = 'Create Post';
  static const String createPostBtn = 'Post';
  static const String createPostPosting = 'Posting…';
  static const String createPostMediaLabel = 'Add photo or video';
  static const String createPostPhotoBtn = 'Photo';
  static const String createPostVideoBtn = 'Video';
  static const String createPostChangeMedia = 'Change';
  static const String createPostTitleLabel = 'TITLE';
  static const String createPostTitleHint = 'e.g. Best Shawarma in TVM';
  static const String createPostDescLabel = 'DESCRIPTION';
  static const String createPostDescHint = 'Tell us about this dish…';
  static const String createPostLocationLabel = 'LOCATION';
  static const String createPostLocationPlaceholder = 'Coming soon';
  static const String createPostLocationBadge = 'Soon';
  static const String createPostGettingUrl = 'Preparing upload…';
  static const String createPostUploadingMedia = 'Uploading media…';
  static const String createPostPublishing = 'Publishing post…';
  static const String createPostStageUploading = 'Uploading';
  static const String createPostStagePublishing = 'Publishing';
  static const String createPostErrorGeneric = 'Something went wrong. Please try again.';

  // Home / Feed
  static const String homeCity = 'Tiruvananthapuram';
  static const String homeExplorePlaceholder = 'Explore';
  static const String homeExploreSub = 'Discover new dishes around you';
  static const String homeSavedPlaceholder = 'Saved';
  static const String homeSavedSub = 'Your saved posts will appear here';
  static const String homeProfilePlaceholder = 'Profile';
  static const String homeProfileSub = 'Manage your profile and settings';
  static const String homeCreatePlaceholder = 'Create Post';
  static const String homeCreateSub = 'Share your food story';

  // Feed category chips
  static const List<Map<String, String>> feedCategories = [
    {'emoji': '🍛', 'name': 'Chicken Curry'},
    {'emoji': '🍗', 'name': 'Butter Chicken'},
    {'emoji': '🫕', 'name': 'Chicken Masala'},
    {'emoji': '🥩', 'name': 'Beef Curry'},
    {'emoji': '🍖', 'name': 'Mandi'},
    {'emoji': '🐟', 'name': 'Fish Curry'},
  ];

  // Placeholder post data
  static const List<Map<String, String>> placeholderPosts = [
    {
      'username': 'Aravind BL',
      'handle': 'xyz.restaurant.tvm',
      'dish': 'Porotta and Beef combo',
      'restaurant': 'xyz restaurant',
      'area': 'Kattakkadam',
      'description':
          'It is a long established fact that a reader will be distracted by the readable content of a page when looking at its layout. The point of using Lorem Ipsum is that it has a more-or-less normal distribution',
      'tag': '#porattabeef',
      'rating': '4.9',
    },
    {
      'username': 'Priya KS',
      'handle': 'priya.foods.kochi',
      'dish': 'Appam and Stew',
      'restaurant': 'Kerala Kitchen',
      'area': 'Ernakulam',
      'description':
          'Soft, lacy appam paired with a coconut milk-based vegetable stew. A classic Kerala breakfast combination that never gets old. Try it fresh!',
      'tag': '#appamstew',
      'rating': '4.7',
    },
    {
      'username': 'Rahul Menon',
      'handle': 'spice.trail.blr',
      'dish': 'Chicken Biryani',
      'restaurant': 'Biryani House',
      'area': 'Kozhikode',
      'description':
          'Aromatic basmati rice layered with tender chicken pieces, slow-cooked with a blend of whole spices. A must-try for biryani lovers.',
      'tag': '#biryani',
      'rating': '4.8',
    },
  ];

  // Cuisines
  static const List<Map<String, String>> cuisines = [
    {'emoji': '🍛', 'name': 'Indian'},
    {'emoji': '🥢', 'name': 'Chinese'},
    {'emoji': '🍝', 'name': 'Italian'},
    {'emoji': '🍜', 'name': 'South Indian'},
    {'emoji': '🍔', 'name': 'American'},
    {'emoji': '🥘', 'name': 'Mediterranean'},
    {'emoji': '🌮', 'name': 'Mexican'},
    {'emoji': '🥗', 'name': 'Healthy'},
  ];
}
