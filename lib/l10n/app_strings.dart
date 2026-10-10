/// Simple Map-based bilingual strings (English + Tamil).
/// Every user-facing string in the app must come from here.
///
/// Usage: `context.tr('key')` or `context.tr('key', {'max': '5000'})`
/// (see lib/widgets/app_scope.dart). Placeholders look like `{name}`.
/// test/l10n_test.dart fails if a Tamil string is missing.
class AppStrings {
  const AppStrings(this.languageCode);

  final String languageCode;

  static const supportedLanguages = ['en', 'ta'];

  /// Returns the string for [key] in the current language, falling back to
  /// English, then to the key itself. Replaces `{param}` placeholders.
  String get(String key, [Map<String, String> params = const {}]) {
    var text = values[languageCode]?[key] ?? values['en']?[key] ?? key;
    params.forEach((name, value) {
      text = text.replaceAll('{$name}', value);
    });
    return text;
  }

  static const Map<String, Map<String, String>> values = {
    'en': _en,
    'ta': _ta,
  };

  // ===================================================================
  // ENGLISH
  // ===================================================================
  static const Map<String, String> _en = {
    // App
    'appName': 'JalMitra',
    'tagline': 'Your Pocket Water Saver',
    'about': 'JalMitra v1.0 · Your Pocket Water Saver\n'
        'Works fully offline. Your data never leaves this phone.',

    // Navigation
    'navHome': 'Home',
    'navMotor': 'Motor Guard',
    'navFlow': 'Flow Timer',
    'navLeak': 'Leak Check',
    'navSettings': 'Settings',

    // Common
    'next': 'Next',
    'back': 'Back',
    'skip': 'Skip',
    'save': 'Save',
    'cancel': 'Cancel',
    'delete': 'Delete',
    'ok': 'OK',
    'start': 'Start',
    'stop': 'Stop',
    'done': 'Done',
    'allow': 'Allow',
    'notNow': 'Not now',
    'today': 'Today',
    'language': 'Language',
    'languageEnglish': 'English',
    'languageTamil': 'தமிழ்',
    'am': 'AM',
    'pm': 'PM',

    // Units
    'unitLitres': 'L',
    'unitCubicMetres': 'm³',
    'unitHp': 'HP',
    'unitRupeesPerUnit': '₹/unit',
    'unitRupees': '₹',
    'unitKwh': 'kWh',
    'unitHours': 'h',
    'unitMinutes': 'min',
    'unitSeconds': 's',

    // Weekdays (DateTime.weekday: 1 = Monday)
    'day1': 'Mon',
    'day2': 'Tue',
    'day3': 'Wed',
    'day4': 'Thu',
    'day5': 'Fri',
    'day6': 'Sat',
    'day7': 'Sun',

    // Validation
    'errEmpty': 'Please enter a value',
    'errNotNumber': 'Please enter a valid number',
    'errPositive': 'Must be more than 0',
    'errTooLarge': 'Must be {max} or less',
    'errWholeNumber': 'Please enter a whole number',
    'errName': 'Please enter a name',
    'errTooFast': 'Too fast to be right. Please measure again.',
    'errMorningLower':
        'Morning reading cannot be lower than the night reading',

    // Onboarding
    'onb1Title': 'Never let your tank overflow',
    'onb1Body':
        'Tell JalMitra when you switch on the motor. It learns how long your '
            'tank takes to fill and rings an alarm before it overflows — even '
            'when the app is closed.',
    'onb2Title': 'Measure every litre',
    'onb2Body':
        'Time a 1-litre bottle at any tap or shower. JalMitra then shows the '
            'litres you use, live, and warns you when you cross your limit.',
    'onb3Title': 'Catch hidden leaks',
    'onb3Body':
        'Count drips for 10 seconds, or compare your water meter at night and '
            'in the morning. No sensors, no internet, no cost.',
    'onbSetUp': 'Set up my home',
    'pageOf': 'Page {current} of {total}',

    // Setup form / settings fields
    'setupTitle': 'Your home setup',
    'setupSubtitle': 'You can change these anytime in Settings.',
    'tankCapacity': 'Overhead tank capacity',
    'tankCapacityHelp': 'Usually printed on the tank, e.g. 500, 1000, 2000',
    'motorHp': 'Motor power',
    'motorHpHelp': 'See the label on the motor, e.g. 0.5, 1, 1.5',
    'electricityRate': 'Electricity rate',
    'electricityRateHelp': 'Rupees per unit (kWh), from your EB bill',
    'overflowMinutes': 'Overflow time before noticed',
    'overflowMinutesHelp':
        'Minutes water usually overflows before someone switches off the motor',
    'saveAndStart': 'Save and start',

    // Permissions
    'permTitle': 'Allow alarms & notifications',
    'permBody':
        'JalMitra needs notifications to ring the "tank almost full" alarm, '
            'even when the app is closed or the phone is locked. Nothing is '
            'sent anywhere — everything stays on your phone.',
    'permOffWarning':
        'Notifications are off. JalMitra cannot ring the alarm when your tank '
            'is almost full.',
    'allowAlarms': 'Allow alarms',

    // Notifications
    'alarmTitle': '{tank}: almost full!',
    'alarmBody': 'Your tank is almost full! Switch off the motor now.',
    'channelMotorName': 'Tank full alarm',
    'channelMotorDesc': 'Rings before your overhead tank overflows',
    'channelReminderName': 'Reminders',
    'channelReminderDesc': 'Morning reminder for the night meter test',
    'meterReminderTitle': 'Night Meter Test',
    'meterReminderBody':
        'Good morning! Enter your water meter reading before anyone uses water.',

    // Home
    'weekSaved': 'This week you saved',
    'motorOn': 'Motor ON',
    'motorRunning': 'Motor running',
    'weeklyChartTitle': 'Litres saved this week',
    'noSavingsYet':
        'No savings yet this week. Use Motor Guard, fix a leak or finish a '
            'challenge to start saving!',

    // Motor Guard
    'demoBadge': 'DEMO MODE',
    'demoExplain':
        'Demo mode is on: 1 minute = 1 second for all Motor Guard timings.',
    'calibrateTitle': 'First, let\'s learn your tank',
    'calibrateIntro':
        'JalMitra needs to know how long your motor takes to fill the tank '
            'from empty. You only do this once.',
    'calibrateStep1': 'Wait until the overhead tank is empty (or nearly empty).',
    'calibrateStep2': 'Switch on the motor and tap "Start Calibration".',
    'calibrateStep3': 'Tap "Tank Full" the moment water reaches the top.',
    'startCalibration': 'Start Calibration',
    'calibrating': 'Calibrating…',
    'calibratingHint':
        'Keep the motor running. Tap "Tank Full" as soon as the tank is full.',
    'calibrationSaved': 'Saved! Your tank fills in about {time}.',
    'calibrationTooShort':
        'That was too short to be a full tank. Please try again.',
    'tankFull': 'Tank Full',
    'fillTimeLearned': 'Your tank fills in about {time}',
    'fillRuns': 'Learned from {n} run(s)',
    'levelQuestion': 'How full is the tank now?',
    'levelEmpty': 'Empty',
    'levelQuarter': 'Quarter',
    'levelHalf': 'Half',
    'levelThreeQuarters': 'Three-quarters',
    'expectedFullIn': 'Tank will be full in {time} (around {clock})',
    'startGuard': 'Motor ON – Start Guard',
    'timeLeft': 'until full',
    'tankShouldBeFull': 'Tank should be full now!',
    'expectedFullAt': 'Expected full at',
    'alarmAt': 'Alarm rings at',
    'cancelGuardTitle': 'Stop Motor Guard?',
    'cancelGuardMsg': 'The alarm will be cancelled and nothing will be saved.',
    'cancelGuardConfirm': 'Stop guard',
    'successTitle': 'Great!',
    'successMsg': 'You saved ~{litres} L and ₹{rupees} today.',
    'learnedMsg': 'JalMitra learned: your tank now fills in about {time}.',
    'notLearnedMsg':
        'This run looked unusual, so the learned fill time was not changed.',

    // Flow Timer
    'chooseFixture': 'Choose a tap or shower',
    'noFixtures':
        'No taps saved yet. Measure one with a 1-litre bottle to get started.',
    'addFixture': 'Add tap / shower',
    'editFixture': 'Edit tap / shower',
    'manageFixtures': 'Manage taps & showers',
    'fixtureCount': '{n} saved',
    'fixtureName': 'Name',
    'fixtureNameHint': 'e.g. Kitchen tap, Bathroom shower',
    'bottleTestTitle': '1-litre bottle test',
    'bottleTestSteps':
        'Hold an empty 1-litre bottle under the tap. Tap Start and open the '
            'tap the way you normally use it. Tap Stop when the bottle is full.',
    'secondsToFill': 'Seconds to fill 1 litre',
    'secondsToFillHelp': 'Filled in by the timer, or type it yourself',
    'flowResult': 'Flow rate: {lps} L/s ({lpm} L/min)',
    'flowPerMinute': '{lpm} L per minute',
    'deleteFixtureTitle': 'Delete tap?',
    'deleteFixtureMsg': '"{name}" will be removed.',
    'limitLabel': 'Limit',
    'limitHelp': 'You will be warned when you use more than this',
    'litresOfLimit': 'litres of {limit} L',
    'elapsed': 'Time',
    'limitCrossed': 'Limit crossed! Please turn off the tap.',
    'usageSaved': 'Saved to history: {litres} L',
    'history': 'Recent usage',
    'noHistory': 'No usage recorded yet.',

    // Leak Check – drips
    'dripTab': 'Drip Calculator',
    'dripIntro':
        'Watch the dripping tap. Tap Start, then tap the big button once for '
            'every drip you see for 10 seconds.',
    'startDripCount': 'Start 10-second count',
    'secondsLeft': '{n} seconds left',
    'tapPerDrip': 'Tap per drip',
    'orEnterDrips': 'Already counted? Enter the number of drips in 10 seconds:',
    'dripsIn10s': 'Drips in 10 s',
    'calculate': 'Calculate',
    'dripsCounted': '{n} drips in 10 seconds',
    'dripWaste': 'This tap wastes {litres} L/month ≈ {buckets} buckets',
    'dripPerDay': 'That is {litres} L every day.',
    'noDrips': 'No drips counted. Great — no leak here!',
    'fixedIt': 'Fixed it!',
    'fixedItSaved': 'Well done! {litres} L/month added to your savings.',
    'countAgain': 'Count again',

    // Leak Check – night meter
    'meterTab': 'Night Meter Test',
    'step1Title': 'Step 1 · At night',
    'step1Body':
        'Close all taps, switch off the motor and make sure no one uses water '
            'overnight. Then enter the reading on your water meter.',
    'meterUnit': 'Your meter shows',
    'meterReading': 'Meter reading',
    'saveNight': 'Save night reading',
    'nightSaved': 'Saved! We will remind you at 7 AM.',
    'nightReadingWas': 'Night reading: {reading} {unit}',
    'step2Title': 'Step 2 · In the morning',
    'step2Body':
        'Before anyone uses water, read the meter again and enter it here.',
    'checkLeak': 'Check for leaks',
    'startOver': 'Start over',
    'leakLikely': 'Hidden leak likely! {litres} L lost overnight.',
    'noLeak': 'No leak detected ✅',
    'leakTipsTitle': 'Where to look',
    'leakTip1':
        'Toilet flush tank: add a few drops of food colour. If colour reaches '
            'the bowl without flushing, it leaks.',
    'leakTip2': 'The float valve (ball valve) inside the overhead tank.',
    'leakTip3': 'Underground pipe from the sump: look for wet soil or extra-green grass.',
    'leakTip4': 'The overflow pipe of the tank, and damp patches on walls or ceilings.',
    'leakTip5': 'If you cannot find it, call a plumber.',
    'newTest': 'New test',

    // Challenges
    'todaysChallenge': "Today's challenge",
    'savesAbout': 'Saves about {litres} L',
    'streakDays': '{n}-day streak',
    'doneToday': 'Done for today ✅',
    'seeAllChallenges': 'See all challenges',
    'challengeDoneMsg': '+{litres} L saved! Streak: {n} day(s).',
    'challengesTitle': 'Water challenges',
    'allChallenges': 'All 30 challenges',
    'badgesTitle': 'Badges',
    'badgeEarned': 'New badge earned!',
    'badge3': '3-day Starter',
    'badge7': '7-day Champion',
    'badge30': '30-day Water Hero',
    'challenge1': 'Turn off the tap while brushing your teeth',
    'challenge2': 'Use a bucket instead of a hose to wash your bike',
    'challenge3': 'Reuse RO reject water for mopping the floor',
    'challenge4': 'Finish your shower in 5 minutes',
    'challenge5': 'Run the washing machine only with a full load',
    'challenge6': 'Wash vegetables in a bowl, not under a running tap',
    'challenge7': 'Pour vegetable-wash water on your plants',
    'challenge8': 'Check your toilet flush for silent leaks',
    'challenge9': 'Pour only the drinking water you need — no half glasses',
    'challenge10': 'Close the tap while soaping your hands or dishes',
    'challenge11': 'Water plants in the early morning or evening',
    'challenge12': 'Take a bucket bath instead of a shower',
    'challenge13': 'Put a filled water bottle inside the flush tank',
    'challenge14': 'Sweep the floor or yard instead of washing it',
    'challenge15': 'Fix or report one dripping tap at home',
    'challenge16': 'Soak dirty dishes before washing them',
    'challenge17': 'Collect AC drain water for your plants',
    'challenge18': 'Use the half-flush button',
    'challenge19': 'Thaw frozen food in the fridge, not under running water',
    'challenge20': 'Reuse rice or dal washing water for plants',
    'challenge21': 'Wash the car with a bucket and cloth',
    'challenge22': "Check the overhead tank's overflow pipe for waste",
    'challenge23': 'Turn off the tap while shaving',
    'challenge24': 'Cover plant pots with dry leaves to keep soil moist',
    'challenge25': 'Keep a bucket outside to collect rainwater',
    'challenge26': 'Wash all the dishes together once, not a few at a time',
    'challenge27': 'Teach a family member one water-saving tip',
    'challenge28': 'Rinse clothes in a bucket, not under a running tap',
    'challenge29': 'Reuse washing machine rinse water to clean the floor',
    'challenge30': 'Use Motor Guard every time you switch on the motor',

    // Settings
    'settingsSaved': 'Settings saved',
    'demoMode': 'Demo Mode',
    'demoModeHelp':
        '1 minute = 1 second for Motor Guard timings and the alarm. '
            'For demonstrations.',
    'motorCalibration': 'Motor calibration',
    'notCalibrated': 'Not calibrated',
    'recalibrate': 'Recalibrate motor',
    'recalibrateTitle': 'Recalibrate motor?',
    'recalibrateMsg':
        'JalMitra will forget the learned fill time. You will need to '
            'calibrate again with an empty tank.',
    'recalibrateDone': 'Calibration cleared. Open Motor Guard to calibrate.',
    'alarmPermissions': 'Alarm permissions',
    'alarmPermissionsHelp':
        'Motor Guard needs notifications and exact alarms to ring on time.',
    'resetAll': 'Reset all data',
    'resetTitle': 'Reset all data?',
    'resetMsg':
        'This deletes your settings, calibration, taps, savings, history and '
            'streak. This cannot be undone.',
    'resetConfirm': 'Delete everything',

    // Home setup
    'yourHome': 'Your home',
    'peopleAtHome': 'People at home',
    'areaType': 'Where do you live?',
    'area_city': 'City',
    'area_town': 'Town',
    'area_village': 'Village',
    'litresPerPerson': 'Litres per person per day',
    'litresPerPersonHelp': 'Leave empty to use the standard {n} L for your area',
    'defaultMotorHp': 'Default motor power (new tanks)',
    'defaultOverflow': 'Default overflow time (new tanks)',

    // Tanks
    'firstTank': 'Your first tank',
    'myTanks': 'My Tanks',
    'tankCount': '{n} tank(s)',
    'addTank': 'Add tank',
    'editTank': 'Edit tank',
    'noTanks': 'No tanks yet. Add your tank in My Tanks.',
    'chooseTank': 'Tank',
    'defaultTankName': 'Overhead tank',
    'tankName': 'Tank name',
    'tankNameHint': 'e.g. Overhead tank, Sump, Loft tank',
    'tankTypeLabel': 'Tank type',
    'tankType_overhead': 'Overhead tank',
    'tankType_sump': 'Sump',
    'tankType_loft': 'Loft tank',
    'tankType_other': 'Other',
    'tankMaterial': 'Material',
    'material_plastic': 'Plastic (HDPE / PVC)',
    'material_concrete': 'RCC / Concrete',
    'material_stainlessSteel': 'Stainless steel',
    'material_galvanisedIron': 'Galvanised iron',
    'material_ferroCement': 'Ferro-cement',
    'material_brick': 'Brick masonry',
    'material_other': 'Other',
    'tankShape': 'Shape',
    'shape_verticalCylinder': 'Round, standing',
    'shape_horizontalCylinder': 'Round, lying down',
    'shape_rectangular': 'Rectangular / square',
    'capacityTyped': 'Type litres',
    'capacityFromSize': 'From size',
    'sizeHelp': 'Measure inside the tank, in metres (e.g. 1.2).',
    'dimDiameter': 'Diameter (width across)',
    'dimLength': 'Length',
    'dimWidth': 'Width',
    'dimHeight': 'Height',
    'unitMetres': 'm',
    'enterAllSizes': 'Enter all sizes to calculate the capacity.',
    'calculatedCapacity': 'Capacity: about {litres} L',
    'motorForTank': 'Motor for this tank',
    'cleaning': 'Cleaning',
    'cleanEvery': 'Clean every',
    'everyMonths': '{n} month(s)',
    'lastCleaned': 'Last cleaned',
    'cleanedDaysAgo': '{n} days ago (keep)',
    'dontKnow': "Don't know",
    'monthsAgo': '{n} month(s) ago',
    'useByDefault': 'Use this tank by default',
    'defaultBadge': 'Default',
    'setDefault': 'Make default',
    'fillsIn': 'Fills in {time}',
    'cleaningDue': 'Cleaning due now',
    'cleaningInDays': 'Next cleaning in {n} days',
    'cleaningUnknown': 'Last cleaning date not set',
    'cleanedToday': 'Cleaned today',
    'markedCleaned': 'Marked as cleaned today',
    'cleaningDueBanner': 'Time to clean: {tanks}',
    'keepOneTank': 'You need at least one tank.',
    'deleteTankTitle': 'Delete tank?',
    'deleteTankMsg': '"{name}" and its learned fill time will be removed.',

    // Motor Guard run results
    'pumpedMsg': 'About {litres} L was pumped into the tank.',
    'lateOverflowMsg':
        'Tank Full was tapped {minutes} min late, so about {litres} L overflowed.',

    // Leaks
    'notFixedYet': 'Not fixed yet? Save it so its daily waste is counted:',
    'leakName': 'Which tap?',
    'leakDefaultName': 'Dripping tap',
    'saveLeak': 'Save as leak (not fixed)',
    'leakSaved': 'Leak saved. Its daily waste is now counted.',
    'activeLeaks': 'Leaks not fixed yet',
    'noActiveLeaks': 'No leaks saved. Great!',
    'leakWastesPerDay': 'Wastes about {litres} L every day',
    'deleteLeakTitle': 'Remove leak?',
    'deleteLeakMsg': '"{name}" will be removed without adding any saving.',

    // Usage
    'usageTitle': 'Water used & wasted',
    'usageToday': 'Water today',
    'seeUsage': 'See details',
    'used': 'Used',
    'wasted': 'Wasted',
    'saved': 'Saved',
    'usedLeftBar': 'Used (left bar)',
    'wastedRightBar': 'Wasted (right bar)',
    'wastedPercentBuckets': 'Wasted {pct}% — about {buckets} buckets today',
    'wastedBuckets': 'Wasted about {buckets} buckets today',
    'noWasteToday': 'No water wasted today. Well done!',
    'homeNeeds':
        'Your home needs about {litres} L/day ({people} people × {lpp} L)',
    'youUsedToday': 'You used {litres} L today',
    'levelUnder': 'Below your daily need',
    'levelNear': 'About your daily need',
    'levelOver': 'Above your daily need',
    'averages': 'Your average: {week} L/day (7 days) · {month} L/day (30 days)',
    'thisWeek': 'This week',
    'thisYear': 'This year ({year})',
    'noUsageYet':
        'No water recorded yet. Use Motor Guard or the Flow Timer and it will '
            'show here.',
    'projectedTitle': 'Projected for the full year',
    'projectedNote':
        'Estimate: your daily average over {days} day(s) × 365.',
    'month1': 'Jan',
    'month2': 'Feb',
    'month3': 'Mar',
    'month4': 'Apr',
    'month5': 'May',
    'month6': 'Jun',
    'month7': 'Jul',
    'month8': 'Aug',
    'month9': 'Sep',
    'month10': 'Oct',
    'month11': 'Nov',
    'month12': 'Dec',

    // Tips
    'tipOfTheDay': 'Tip of the day',
    'tipNotifications': 'Morning tip notification',
    'tipNotificationsHelp': 'A new water-saving tip every day at 8 AM',
    'channelTipName': 'Daily tips',
    'channelTipDesc': 'One water-saving tip every morning',
    'batteryNote':
        'On Xiaomi, Oppo, Vivo, Realme and some other phones, open Settings → '
            'Apps → JalMitra → Battery and choose "No restrictions", or alarms '
            'may be blocked.',
  };

  // ===================================================================
  // TAMIL
  // ===================================================================
  static const Map<String, String> _ta = {
    // App
    'appName': 'ஜல்மித்ரா',
    'tagline': 'உங்கள் கைப்பேசி நீர் சேமிப்பாளர்',
    'about': 'ஜல்மித்ரா v1.0 · உங்கள் கைப்பேசி நீர் சேமிப்பாளர்\n'
        'இணையம் இல்லாமல் முழுமையாக இயங்கும். உங்கள் தரவு இந்தக் கைப்பேசியை '
        'விட்டு வெளியே போகாது.',

    // Navigation
    'navHome': 'முகப்பு',
    'navMotor': 'மோட்டார் காவல்',
    'navFlow': 'நீர் அளவி',
    'navLeak': 'கசிவு சோதனை',
    'navSettings': 'அமைப்புகள்',

    // Common
    'next': 'அடுத்து',
    'back': 'பின்செல்',
    'skip': 'தவிர்',
    'save': 'சேமி',
    'cancel': 'ரத்து',
    'delete': 'நீக்கு',
    'ok': 'சரி',
    'start': 'தொடங்கு',
    'stop': 'நிறுத்து',
    'done': 'முடிந்தது',
    'allow': 'அனுமதி',
    'notNow': 'இப்போது வேண்டாம்',
    'today': 'இன்று',
    'language': 'மொழி',
    'languageEnglish': 'English',
    'languageTamil': 'தமிழ்',
    'am': 'AM',
    'pm': 'PM',

    // Units
    'unitLitres': 'லி',
    'unitCubicMetres': 'மீ³',
    'unitHp': 'HP',
    'unitRupeesPerUnit': '₹/யூனிட்',
    'unitRupees': '₹',
    'unitKwh': 'kWh',
    'unitHours': 'மணி',
    'unitMinutes': 'நிமி',
    'unitSeconds': 'வி',

    // Weekdays
    'day1': 'திங்',
    'day2': 'செவ்',
    'day3': 'புத',
    'day4': 'வியா',
    'day5': 'வெள்',
    'day6': 'சனி',
    'day7': 'ஞாயி',

    // Validation
    'errEmpty': 'தயவுசெய்து ஒரு மதிப்பை உள்ளிடவும்',
    'errNotNumber': 'தயவுசெய்து சரியான எண்ணை உள்ளிடவும்',
    'errPositive': '0-ஐ விட அதிகமாக இருக்க வேண்டும்',
    'errTooLarge': '{max} அல்லது அதற்குக் குறைவாக இருக்க வேண்டும்',
    'errWholeNumber': 'தயவுசெய்து முழு எண்ணை உள்ளிடவும்',
    'errName': 'தயவுசெய்து ஒரு பெயரை உள்ளிடவும்',
    'errTooFast': 'இது மிக வேகம், சரியாக இருக்காது. மீண்டும் அளவிடுங்கள்.',
    'errMorningLower':
        'காலை அளவீடு இரவு அளவீட்டை விடக் குறைவாக இருக்க முடியாது',

    // Onboarding
    'onb1Title': 'தொட்டி நிரம்பி வழிய விடாதீர்கள்',
    'onb1Body':
        'மோட்டாரை இயக்கும்போது ஜல்மித்ராவிடம் சொல்லுங்கள். உங்கள் தொட்டி '
            'நிரம்ப எவ்வளவு நேரம் ஆகும் என்பதை அது கற்றுக்கொண்டு, நிரம்பி '
            'வழிவதற்கு முன்பே அலாரம் அடிக்கும் — செயலி மூடியிருந்தாலும் கூட.',
    'onb2Title': 'ஒவ்வொரு லிட்டரையும் அளவிடுங்கள்',
    'onb2Body':
        'எந்தக் குழாய் அல்லது ஷவரிலும் 1 லிட்டர் பாட்டில் நிரம்பும் நேரத்தை '
            'அளவிடுங்கள். பிறகு நீங்கள் பயன்படுத்தும் லிட்டர்களை ஜல்மித்ரா '
            'நேரலையாகக் காட்டி, வரம்பைத் தாண்டும்போது எச்சரிக்கும்.',
    'onb3Title': 'மறைந்த கசிவுகளைக் கண்டறியுங்கள்',
    'onb3Body':
        '10 விநாடிகள் சொட்டுகளை எண்ணுங்கள், அல்லது இரவும் காலையும் நீர் '
            'மீட்டரை ஒப்பிடுங்கள். சென்சார் இல்லை, இணையம் இல்லை, செலவும் இல்லை.',
    'onbSetUp': 'என் வீட்டை அமைக்கவும்',
    'pageOf': 'பக்கம் {current} / {total}',

    // Setup form / settings fields
    'setupTitle': 'உங்கள் வீட்டு அமைப்பு',
    'setupSubtitle': 'இவற்றை எப்போது வேண்டுமானாலும் அமைப்புகளில் மாற்றலாம்.',
    'tankCapacity': 'மேல்நிலைத் தொட்டி கொள்ளளவு',
    'tankCapacityHelp':
        'பொதுவாகத் தொட்டியில் அச்சிடப்பட்டிருக்கும், எ.கா. 500, 1000, 2000',
    'motorHp': 'மோட்டார் திறன்',
    'motorHpHelp': 'மோட்டாரின் லேபிளைப் பாருங்கள், எ.கா. 0.5, 1, 1.5',
    'electricityRate': 'மின் கட்டணம்',
    'electricityRateHelp': 'ஒரு யூனிட்டுக்கு (kWh) ரூபாய், உங்கள் மின் ரசீதில்',
    'overflowMinutes': 'கவனிக்கும் முன் வழியும் நேரம்',
    'overflowMinutesHelp':
        'மோட்டாரை யாராவது அணைக்கும் முன் பொதுவாக எத்தனை நிமிடம் நீர் வழிகிறது',
    'saveAndStart': 'சேமித்துத் தொடங்கு',

    // Permissions
    'permTitle': 'அலாரம் & அறிவிப்புகளை அனுமதியுங்கள்',
    'permBody':
        'செயலி மூடியிருந்தாலும், கைப்பேசி பூட்டியிருந்தாலும் "தொட்டி கிட்டத்தட்ட '
            'நிரம்பியது" அலாரம் அடிக்க ஜல்மித்ராவுக்கு அறிவிப்பு அனுமதி தேவை. '
            'எதுவும் எங்கும் அனுப்பப்படாது — அனைத்தும் உங்கள் கைப்பேசியிலேயே இருக்கும்.',
    'permOffWarning':
        'அறிவிப்புகள் அணைக்கப்பட்டுள்ளன. தொட்டி நிரம்பும்போது ஜல்மித்ராவால் '
            'அலாரம் அடிக்க முடியாது.',
    'allowAlarms': 'அலாரத்தை அனுமதி',

    // Notifications
    'alarmTitle': '{tank}: கிட்டத்தட்ட நிரம்பியது!',
    'alarmBody':
        'உங்கள் தொட்டி கிட்டத்தட்ட நிரம்பிவிட்டது! இப்போதே மோட்டாரை அணையுங்கள்.',
    'channelMotorName': 'தொட்டி நிரம்பும் அலாரம்',
    'channelMotorDesc': 'மேல்நிலைத் தொட்டி வழிவதற்கு முன் அலாரம் அடிக்கும்',
    'channelReminderName': 'நினைவூட்டல்கள்',
    'channelReminderDesc': 'இரவு மீட்டர் சோதனைக்கான காலை நினைவூட்டல்',
    'meterReminderTitle': 'இரவு மீட்டர் சோதனை',
    'meterReminderBody':
        'காலை வணக்கம்! யாரும் நீர் பயன்படுத்தும் முன் நீர் மீட்டர் அளவீட்டை உள்ளிடுங்கள்.',

    // Home
    'weekSaved': 'இந்த வாரம் நீங்கள் சேமித்தது',
    'motorOn': 'மோட்டார் ON',
    'motorRunning': 'மோட்டார் இயங்குகிறது',
    'weeklyChartTitle': 'இந்த வாரம் சேமித்த லிட்டர்கள்',
    'noSavingsYet':
        'இந்த வாரம் இன்னும் சேமிப்பு இல்லை. மோட்டார் காவலைப் பயன்படுத்துங்கள், '
            'கசிவைச் சரிசெய்யுங்கள் அல்லது ஒரு சவாலை முடியுங்கள்!',

    // Motor Guard
    'demoBadge': 'டெமோ முறை',
    'demoExplain':
        'டெமோ முறை இயக்கத்தில் உள்ளது: மோட்டார் காவலின் எல்லா நேரங்களிலும் 1 நிமிடம் = 1 விநாடி.',
    'calibrateTitle': 'முதலில், உங்கள் தொட்டியை அறிந்துகொள்வோம்',
    'calibrateIntro':
        'காலியான தொட்டியை நிரப்ப உங்கள் மோட்டாருக்கு எவ்வளவு நேரம் ஆகிறது என்பது '
            'ஜல்மித்ராவுக்குத் தெரிய வேண்டும். இதை ஒருமுறை மட்டும் செய்தால் போதும்.',
    'calibrateStep1':
        'மேல்நிலைத் தொட்டி காலியாகும் வரை (அல்லது கிட்டத்தட்ட காலியாகும் வரை) காத்திருங்கள்.',
    'calibrateStep2': 'மோட்டாரை இயக்கி "அளவீட்டைத் தொடங்கு" என்பதைத் தட்டுங்கள்.',
    'calibrateStep3':
        'நீர் மேலே வந்தவுடன் "தொட்டி நிரம்பியது" என்பதைத் தட்டுங்கள்.',
    'startCalibration': 'அளவீட்டைத் தொடங்கு',
    'calibrating': 'அளவிடுகிறது…',
    'calibratingHint':
        'மோட்டார் இயங்கட்டும். தொட்டி நிரம்பியவுடன் "தொட்டி நிரம்பியது" என்பதைத் தட்டுங்கள்.',
    'calibrationSaved': 'சேமிக்கப்பட்டது! உங்கள் தொட்டி சுமார் {time}-இல் நிரம்பும்.',
    'calibrationTooShort':
        'முழுத் தொட்டிக்கு இது மிகக் குறைவான நேரம். மீண்டும் முயற்சிக்கவும்.',
    'tankFull': 'தொட்டி நிரம்பியது',
    'fillTimeLearned': 'உங்கள் தொட்டி சுமார் {time}-இல் நிரம்பும்',
    'fillRuns': '{n} முறை இயக்கியதிலிருந்து கற்றது',
    'levelQuestion': 'இப்போது தொட்டியில் எவ்வளவு நீர் உள்ளது?',
    'levelEmpty': 'காலி',
    'levelQuarter': 'கால் பங்கு',
    'levelHalf': 'பாதி',
    'levelThreeQuarters': 'முக்கால் பங்கு',
    'expectedFullIn': 'தொட்டி {time}-இல் நிரம்பும் (சுமார் {clock})',
    'startGuard': 'மோட்டார் ON – காவலைத் தொடங்கு',
    'timeLeft': 'நிரம்ப மீதமுள்ளது',
    'tankShouldBeFull': 'தொட்டி இப்போது நிரம்பியிருக்கும்!',
    'expectedFullAt': 'நிரம்பும் நேரம்',
    'alarmAt': 'அலாரம் அடிக்கும் நேரம்',
    'cancelGuardTitle': 'மோட்டார் காவலை நிறுத்தவா?',
    'cancelGuardMsg': 'அலாரம் ரத்து செய்யப்படும், எதுவும் சேமிக்கப்படாது.',
    'cancelGuardConfirm': 'காவலை நிறுத்து',
    'successTitle': 'அருமை!',
    'successMsg': 'இன்று சுமார் {litres} லி நீரையும் ₹{rupees}-ஐயும் சேமித்தீர்கள்.',
    'learnedMsg':
        'ஜல்மித்ரா கற்றுக்கொண்டது: உங்கள் தொட்டி இப்போது சுமார் {time}-இல் நிரம்பும்.',
    'notLearnedMsg':
        'இந்த முறை வழக்கத்துக்கு மாறாக இருந்ததால், கற்ற நிரப்பு நேரம் மாற்றப்படவில்லை.',

    // Flow Timer
    'chooseFixture': 'குழாய் அல்லது ஷவரைத் தேர்ந்தெடுங்கள்',
    'noFixtures':
        'இன்னும் குழாய் எதுவும் சேமிக்கவில்லை. தொடங்க 1 லிட்டர் பாட்டிலால் ஒன்றை அளவிடுங்கள்.',
    'addFixture': 'குழாய் / ஷவர் சேர்',
    'editFixture': 'குழாய் / ஷவரைத் திருத்து',
    'manageFixtures': 'குழாய்கள் & ஷவர்களை நிர்வகி',
    'fixtureCount': '{n} சேமிக்கப்பட்டுள்ளன',
    'fixtureName': 'பெயர்',
    'fixtureNameHint': 'எ.கா. சமையலறைக் குழாய், குளியலறை ஷவர்',
    'bottleTestTitle': '1 லிட்டர் பாட்டில் சோதனை',
    'bottleTestSteps':
        'காலியான 1 லிட்டர் பாட்டிலைக் குழாயின் கீழ் பிடியுங்கள். "தொடங்கு" தட்டி, '
            'வழக்கம்போல் குழாயைத் திறங்கள். பாட்டில் நிரம்பியதும் "நிறுத்து" தட்டுங்கள்.',
    'secondsToFill': '1 லிட்டர் நிரம்ப ஆகும் விநாடிகள்',
    'secondsToFillHelp': 'டைமர் நிரப்பும், அல்லது நீங்களே உள்ளிடலாம்',
    'flowResult': 'நீர் ஓட்டம்: {lps} லி/வி ({lpm} லி/நிமி)',
    'flowPerMinute': 'நிமிடத்துக்கு {lpm} லி',
    'deleteFixtureTitle': 'குழாயை நீக்கவா?',
    'deleteFixtureMsg': '"{name}" நீக்கப்படும்.',
    'limitLabel': 'வரம்பு',
    'limitHelp': 'இதை விட அதிகம் பயன்படுத்தினால் எச்சரிக்கப்படுவீர்கள்',
    'litresOfLimit': '{limit} லி வரம்பில் லிட்டர்கள்',
    'elapsed': 'நேரம்',
    'limitCrossed': 'வரம்பைத் தாண்டிவிட்டது! தயவுசெய்து குழாயை மூடுங்கள்.',
    'usageSaved': 'வரலாற்றில் சேமிக்கப்பட்டது: {litres} லி',
    'history': 'சமீபத்திய பயன்பாடு',
    'noHistory': 'இன்னும் பயன்பாடு எதுவும் பதிவாகவில்லை.',

    // Leak Check – drips
    'dripTab': 'சொட்டுக் கணிப்பான்',
    'dripIntro':
        'சொட்டும் குழாயைக் கவனியுங்கள். "தொடங்கு" தட்டி, 10 விநாடிகளுக்கு ஒவ்வொரு '
            'சொட்டுக்கும் பெரிய பொத்தானை ஒருமுறை தட்டுங்கள்.',
    'startDripCount': '10 விநாடி எண்ணிக்கையைத் தொடங்கு',
    'secondsLeft': 'இன்னும் {n} விநாடிகள்',
    'tapPerDrip': 'ஒவ்வொரு சொட்டுக்கும் தட்டு',
    'orEnterDrips': 'ஏற்கனவே எண்ணிவிட்டீர்களா? 10 விநாடியில் விழுந்த சொட்டுகளை உள்ளிடுங்கள்:',
    'dripsIn10s': '10 வி-இல் சொட்டுகள்',
    'calculate': 'கணக்கிடு',
    'dripsCounted': '10 விநாடியில் {n} சொட்டுகள்',
    'dripWaste': 'இந்தக் குழாய் மாதம் {litres} லி வீணாக்குகிறது ≈ {buckets} வாளிகள்',
    'dripPerDay': 'அதாவது தினமும் {litres} லி.',
    'noDrips': 'சொட்டு எதுவும் இல்லை. அருமை — இங்கே கசிவு இல்லை!',
    'fixedIt': 'சரிசெய்துவிட்டேன்!',
    'fixedItSaved': 'நன்று! மாதம் {litres} லி உங்கள் சேமிப்பில் சேர்க்கப்பட்டது.',
    'countAgain': 'மீண்டும் எண்ணு',

    // Leak Check – night meter
    'meterTab': 'இரவு மீட்டர் சோதனை',
    'step1Title': 'படி 1 · இரவில்',
    'step1Body':
        'எல்லாக் குழாய்களையும் மூடி, மோட்டாரை அணைத்து, இரவில் யாரும் நீர் '
            'பயன்படுத்தாமல் பார்த்துக்கொள்ளுங்கள். பிறகு நீர் மீட்டரில் உள்ள அளவீட்டை உள்ளிடுங்கள்.',
    'meterUnit': 'உங்கள் மீட்டர் காட்டுவது',
    'meterReading': 'மீட்டர் அளவீடு',
    'saveNight': 'இரவு அளவீட்டைச் சேமி',
    'nightSaved': 'சேமிக்கப்பட்டது! காலை 7 மணிக்கு நினைவூட்டுவோம்.',
    'nightReadingWas': 'இரவு அளவீடு: {reading} {unit}',
    'step2Title': 'படி 2 · காலையில்',
    'step2Body':
        'யாரும் நீர் பயன்படுத்தும் முன், மீட்டரை மீண்டும் பார்த்து இங்கே உள்ளிடுங்கள்.',
    'checkLeak': 'கசிவைச் சோதி',
    'startOver': 'மீண்டும் தொடங்கு',
    'leakLikely': 'மறைந்த கசிவு இருக்கலாம்! இரவில் {litres} லி வீணானது.',
    'noLeak': 'கசிவு எதுவும் இல்லை ✅',
    'leakTipsTitle': 'எங்கே பார்க்க வேண்டும்',
    'leakTip1':
        'கழிப்பறை ஃப்ளஷ் தொட்டி: சில சொட்டு உணவு வண்ணம் சேருங்கள். ஃப்ளஷ் '
            'செய்யாமலே வண்ணம் கோப்பையில் வந்தால் கசிவு உள்ளது.',
    'leakTip2': 'மேல்நிலைத் தொட்டிக்குள் உள்ள மிதவை வால்வு (பால் வால்வு).',
    'leakTip3': 'சம்ப்பிலிருந்து வரும் நிலத்தடிக் குழாய்: ஈர மண் அல்லது அதிகப் பச்சையான புல் உள்ளதா எனப் பாருங்கள்.',
    'leakTip4': 'தொட்டியின் வழிதல் குழாய், சுவர் அல்லது கூரையில் ஈரத் திட்டுகள்.',
    'leakTip5': 'கண்டுபிடிக்க முடியவில்லை என்றால், பிளம்பரை அழையுங்கள்.',
    'newTest': 'புதிய சோதனை',

    // Challenges
    'todaysChallenge': 'இன்றைய சவால்',
    'savesAbout': 'சுமார் {litres} லி சேமிக்கும்',
    'streakDays': 'தொடர்ந்து {n} நாட்கள்',
    'doneToday': 'இன்றைக்கு முடிந்தது ✅',
    'seeAllChallenges': 'எல்லாச் சவால்களையும் பார்',
    'challengeDoneMsg': '+{litres} லி சேமிப்பு! தொடர்: {n} நாள்.',
    'challengesTitle': 'நீர் சவால்கள்',
    'allChallenges': 'அனைத்து 30 சவால்கள்',
    'badgesTitle': 'பதக்கங்கள்',
    'badgeEarned': 'புதிய பதக்கம் கிடைத்தது!',
    'badge3': '3 நாள் தொடக்கம்',
    'badge7': '7 நாள் சாம்பியன்',
    'badge30': '30 நாள் நீர் நாயகன்',
    'challenge1': 'பல் துலக்கும்போது குழாயை மூடி வையுங்கள்',
    'challenge2': 'பைக்கைக் கழுவ குழாய்க்குப் பதிலாக வாளியைப் பயன்படுத்துங்கள்',
    'challenge3': 'RO கழிவு நீரைத் தரை துடைக்கப் பயன்படுத்துங்கள்',
    'challenge4': '5 நிமிடத்தில் குளியலை முடியுங்கள்',
    'challenge5': 'முழு அளவு துணிகள் இருக்கும்போது மட்டுமே வாஷிங் மெஷினை இயக்குங்கள்',
    'challenge6': 'காய்கறிகளை ஓடும் குழாயின் கீழ் அல்ல, பாத்திரத்தில் கழுவுங்கள்',
    'challenge7': 'காய்கறி கழுவிய நீரைச் செடிகளுக்கு ஊற்றுங்கள்',
    'challenge8': 'கழிப்பறை ஃப்ளஷில் சத்தமில்லாக் கசிவு உள்ளதா எனப் பாருங்கள்',
    'challenge9': 'தேவையான அளவு மட்டுமே குடிநீர் ஊற்றுங்கள் — பாதி டம்ளர் வீணாக வேண்டாம்',
    'challenge10': 'கை அல்லது பாத்திரங்களுக்குச் சோப்பு போடும்போது குழாயை மூடுங்கள்',
    'challenge11': 'அதிகாலை அல்லது மாலையில் செடிகளுக்கு நீர் ஊற்றுங்கள்',
    'challenge12': 'ஷவருக்குப் பதிலாக வாளியில் குளியுங்கள்',
    'challenge13': 'ஃப்ளஷ் தொட்டிக்குள் நீர் நிரப்பிய பாட்டிலை வையுங்கள்',
    'challenge14': 'தரை அல்லது முற்றத்தைக் கழுவாமல் பெருக்குங்கள்',
    'challenge15': 'வீட்டில் சொட்டும் ஒரு குழாயைச் சரிசெய்யுங்கள் அல்லது தெரிவியுங்கள்',
    'challenge16': 'கழுவும் முன் அழுக்குப் பாத்திரங்களை ஊறவையுங்கள்',
    'challenge17': 'ஏசியிலிருந்து வடியும் நீரைச் செடிகளுக்குச் சேமியுங்கள்',
    'challenge18': 'அரை ஃப்ளஷ் பொத்தானைப் பயன்படுத்துங்கள்',
    'challenge19': 'உறைந்த உணவை ஓடும் நீரில் அல்ல, ஃப்ரிட்ஜில் உருகவிடுங்கள்',
    'challenge20': 'அரிசி அல்லது பருப்பு கழுவிய நீரைச் செடிகளுக்குப் பயன்படுத்துங்கள்',
    'challenge21': 'காரை வாளியும் துணியும் கொண்டு கழுவுங்கள்',
    'challenge22': 'மேல்நிலைத் தொட்டியின் வழிதல் குழாயில் நீர் வீணாகிறதா எனப் பாருங்கள்',
    'challenge23': 'ஷேவ் செய்யும்போது குழாயை மூடுங்கள்',
    'challenge24': 'மண் ஈரமாக இருக்கச் செடித் தொட்டிகளை உலர்ந்த இலைகளால் மூடுங்கள்',
    'challenge25': 'மழைநீரைச் சேமிக்க ஒரு வாளியை வெளியே வையுங்கள்',
    'challenge26': 'பாத்திரங்களை அவ்வப்போது அல்ல, ஒரே முறையாகக் கழுவுங்கள்',
    'challenge27': 'குடும்பத்தில் ஒருவருக்கு ஒரு நீர் சேமிப்புக் குறிப்பைச் சொல்லிக் கொடுங்கள்',
    'challenge28': 'துணிகளை ஓடும் குழாயில் அல்ல, வாளியில் அலசுங்கள்',
    'challenge29': 'வாஷிங் மெஷின் அலசிய நீரைத் தரை சுத்தம் செய்யப் பயன்படுத்துங்கள்',
    'challenge30': 'மோட்டாரை இயக்கும் ஒவ்வொரு முறையும் மோட்டார் காவலைப் பயன்படுத்துங்கள்',

    // Settings
    'settingsSaved': 'அமைப்புகள் சேமிக்கப்பட்டன',
    'demoMode': 'டெமோ முறை',
    'demoModeHelp':
        'மோட்டார் காவல் நேரங்கள் மற்றும் அலாரத்துக்கு 1 நிமிடம் = 1 விநாடி. '
            'செய்முறை விளக்கத்துக்கு.',
    'motorCalibration': 'மோட்டார் அளவீடு',
    'notCalibrated': 'இன்னும் அளவிடவில்லை',
    'recalibrate': 'மோட்டாரை மீண்டும் அளவிடு',
    'recalibrateTitle': 'மோட்டாரை மீண்டும் அளவிடவா?',
    'recalibrateMsg':
        'கற்ற நிரப்பு நேரத்தை ஜல்மித்ரா மறந்துவிடும். காலியான தொட்டியுடன் '
            'மீண்டும் அளவிட வேண்டும்.',
    'recalibrateDone': 'அளவீடு அழிக்கப்பட்டது. அளவிட மோட்டார் காவலைத் திறங்கள்.',
    'alarmPermissions': 'அலாரம் அனுமதிகள்',
    'alarmPermissionsHelp':
        'சரியான நேரத்தில் அலாரம் அடிக்க மோட்டார் காவலுக்கு அறிவிப்புகளும் துல்லியமான அலாரங்களும் தேவை.',
    'resetAll': 'எல்லாத் தரவையும் அழி',
    'resetTitle': 'எல்லாத் தரவையும் அழிக்கவா?',
    'resetMsg':
        'உங்கள் அமைப்புகள், அளவீடு, குழாய்கள், சேமிப்பு, வரலாறு மற்றும் தொடர் '
            'அனைத்தும் நீக்கப்படும். இதைத் திரும்பப் பெற முடியாது.',
    'resetConfirm': 'அனைத்தையும் நீக்கு',

    // Home setup
    'yourHome': 'உங்கள் வீடு',
    'peopleAtHome': 'வீட்டில் உள்ளவர்கள்',
    'areaType': 'நீங்கள் எங்கே வசிக்கிறீர்கள்?',
    'area_city': 'நகரம்',
    'area_town': 'சிறு நகரம்',
    'area_village': 'கிராமம்',
    'litresPerPerson': 'ஒருவருக்கு ஒரு நாளைக்கு லிட்டர்',
    'litresPerPersonHelp':
        'உங்கள் பகுதிக்கான நிலையான {n} லி-ஐப் பயன்படுத்த காலியாக விடுங்கள்',
    'defaultMotorHp': 'இயல்பு மோட்டார் திறன் (புதிய தொட்டிகள்)',
    'defaultOverflow': 'இயல்பு வழியும் நேரம் (புதிய தொட்டிகள்)',

    // Tanks
    'firstTank': 'உங்கள் முதல் தொட்டி',
    'myTanks': 'என் தொட்டிகள்',
    'tankCount': '{n} தொட்டி(கள்)',
    'addTank': 'தொட்டி சேர்',
    'editTank': 'தொட்டியைத் திருத்து',
    'noTanks': 'இன்னும் தொட்டி இல்லை. "என் தொட்டிகள்" பகுதியில் சேர்க்கவும்.',
    'chooseTank': 'தொட்டி',
    'defaultTankName': 'மேல்நிலைத் தொட்டி',
    'tankName': 'தொட்டியின் பெயர்',
    'tankNameHint': 'எ.கா. மேல்நிலைத் தொட்டி, சம்ப், லாஃப்ட் தொட்டி',
    'tankTypeLabel': 'தொட்டி வகை',
    'tankType_overhead': 'மேல்நிலைத் தொட்டி',
    'tankType_sump': 'சம்ப் (தரைத் தொட்டி)',
    'tankType_loft': 'லாஃப்ட் தொட்டி',
    'tankType_other': 'மற்றவை',
    'tankMaterial': 'பொருள்',
    'material_plastic': 'பிளாஸ்டிக் (HDPE / PVC)',
    'material_concrete': 'RCC / கான்கிரீட்',
    'material_stainlessSteel': 'எஃகு (ஸ்டெயின்லெஸ் ஸ்டீல்)',
    'material_galvanisedIron': 'கால்வனைஸ்டு இரும்பு',
    'material_ferroCement': 'ஃபெரோ-சிமென்ட்',
    'material_brick': 'செங்கல் கட்டுமானம்',
    'material_other': 'மற்றவை',
    'tankShape': 'வடிவம்',
    'shape_verticalCylinder': 'உருளை, நிற்கும்',
    'shape_horizontalCylinder': 'உருளை, படுத்த நிலை',
    'shape_rectangular': 'செவ்வகம் / சதுரம்',
    'capacityTyped': 'லிட்டர் உள்ளிடு',
    'capacityFromSize': 'அளவிலிருந்து',
    'sizeHelp': 'தொட்டியின் உள்ளே மீட்டரில் அளவிடுங்கள் (எ.கா. 1.2).',
    'dimDiameter': 'விட்டம் (குறுக்கு அகலம்)',
    'dimLength': 'நீளம்',
    'dimWidth': 'அகலம்',
    'dimHeight': 'உயரம்',
    'unitMetres': 'மீ',
    'enterAllSizes': 'கொள்ளளவைக் கணக்கிட எல்லா அளவுகளையும் உள்ளிடுங்கள்.',
    'calculatedCapacity': 'கொள்ளளவு: சுமார் {litres} லி',
    'motorForTank': 'இந்தத் தொட்டிக்கான மோட்டார்',
    'cleaning': 'சுத்தம் செய்தல்',
    'cleanEvery': 'சுத்தம் செய்யும் இடைவெளி',
    'everyMonths': '{n} மாதம்',
    'lastCleaned': 'கடைசியாகச் சுத்தம் செய்தது',
    'cleanedDaysAgo': '{n} நாட்களுக்கு முன் (மாற்ற வேண்டாம்)',
    'dontKnow': 'தெரியாது',
    'monthsAgo': '{n} மாதம் முன்',
    'useByDefault': 'இந்தத் தொட்டியை இயல்பாகப் பயன்படுத்து',
    'defaultBadge': 'இயல்பு',
    'setDefault': 'இயல்பாக்கு',
    'fillsIn': '{time}-இல் நிரம்பும்',
    'cleaningDue': 'இப்போது சுத்தம் செய்ய வேண்டும்',
    'cleaningInDays': 'அடுத்த சுத்தம் {n} நாட்களில்',
    'cleaningUnknown': 'கடைசிச் சுத்தம் செய்த தேதி இல்லை',
    'cleanedToday': 'இன்று சுத்தம் செய்தேன்',
    'markedCleaned': 'இன்று சுத்தம் செய்ததாகக் குறிக்கப்பட்டது',
    'cleaningDueBanner': 'சுத்தம் செய்யும் நேரம்: {tanks}',
    'keepOneTank': 'குறைந்தது ஒரு தொட்டியாவது இருக்க வேண்டும்.',
    'deleteTankTitle': 'தொட்டியை நீக்கவா?',
    'deleteTankMsg': '"{name}" மற்றும் அதன் கற்ற நிரப்பு நேரம் நீக்கப்படும்.',

    // Motor Guard run results
    'pumpedMsg': 'சுமார் {litres} லி நீர் தொட்டியில் ஏற்றப்பட்டது.',
    'lateOverflowMsg':
        '"தொட்டி நிரம்பியது" {minutes} நிமி தாமதமாகத் தட்டப்பட்டதால் சுமார் {litres} லி வழிந்தது.',

    // Leaks
    'notFixedYet':
        'இன்னும் சரிசெய்யவில்லையா? தினசரி வீணாவது கணக்கிடப்பட இதைச் சேமியுங்கள்:',
    'leakName': 'எந்தக் குழாய்?',
    'leakDefaultName': 'சொட்டும் குழாய்',
    'saveLeak': 'கசிவாகச் சேமி (சரிசெய்யவில்லை)',
    'leakSaved': 'கசிவு சேமிக்கப்பட்டது. அதன் தினசரி வீணாவது இப்போது கணக்கிடப்படும்.',
    'activeLeaks': 'இன்னும் சரிசெய்யாத கசிவுகள்',
    'noActiveLeaks': 'சேமித்த கசிவு எதுவும் இல்லை. அருமை!',
    'leakWastesPerDay': 'தினமும் சுமார் {litres} லி வீணாகிறது',
    'deleteLeakTitle': 'கசிவை நீக்கவா?',
    'deleteLeakMsg': '"{name}" சேமிப்பு எதுவும் சேர்க்காமல் நீக்கப்படும்.',

    // Usage
    'usageTitle': 'பயன்பட்ட & வீணான நீர்',
    'usageToday': 'இன்றைய நீர்',
    'seeUsage': 'விவரங்களைப் பார்',
    'used': 'பயன்பட்டது',
    'wasted': 'வீணானது',
    'saved': 'சேமித்தது',
    'usedLeftBar': 'பயன்பட்டது (இடது பட்டை)',
    'wastedRightBar': 'வீணானது (வலது பட்டை)',
    'wastedPercentBuckets': 'இன்று {pct}% வீணானது — சுமார் {buckets} வாளிகள்',
    'wastedBuckets': 'இன்று சுமார் {buckets} வாளிகள் வீணானது',
    'noWasteToday': 'இன்று நீர் எதுவும் வீணாகவில்லை. நன்று!',
    'homeNeeds':
        'உங்கள் வீட்டுக்குத் தினமும் சுமார் {litres} லி தேவை ({people} பேர் × {lpp} லி)',
    'youUsedToday': 'இன்று {litres} லி பயன்படுத்தினீர்கள்',
    'levelUnder': 'தினசரித் தேவையை விடக் குறைவு',
    'levelNear': 'தினசரித் தேவை அளவு',
    'levelOver': 'தினசரித் தேவையை விட அதிகம்',
    'averages': 'உங்கள் சராசரி: {week} லி/நாள் (7 நாள்) · {month} லி/நாள் (30 நாள்)',
    'thisWeek': 'இந்த வாரம்',
    'thisYear': 'இந்த ஆண்டு ({year})',
    'noUsageYet':
        'இன்னும் நீர் பதிவாகவில்லை. மோட்டார் காவல் அல்லது நீர் அளவியைப் '
            'பயன்படுத்தினால் இங்கே தெரியும்.',
    'projectedTitle': 'முழு ஆண்டுக்கான கணிப்பு',
    'projectedNote': 'மதிப்பீடு: {days} நாளின் தினசரிச் சராசரி × 365.',
    'month1': 'ஜன',
    'month2': 'பிப்',
    'month3': 'மார்',
    'month4': 'ஏப்',
    'month5': 'மே',
    'month6': 'ஜூன்',
    'month7': 'ஜூலை',
    'month8': 'ஆக',
    'month9': 'செப்',
    'month10': 'அக்',
    'month11': 'நவ',
    'month12': 'டிச',

    // Tips
    'tipOfTheDay': 'இன்றைய குறிப்பு',
    'tipNotifications': 'காலைக் குறிப்பு அறிவிப்பு',
    'tipNotificationsHelp': 'தினமும் காலை 8 மணிக்கு ஒரு புதிய நீர் சேமிப்புக் குறிப்பு',
    'channelTipName': 'தினசரிக் குறிப்புகள்',
    'channelTipDesc': 'ஒவ்வொரு காலையும் ஒரு நீர் சேமிப்புக் குறிப்பு',
    'batteryNote':
        'Xiaomi, Oppo, Vivo, Realme போன்ற கைப்பேசிகளில் Settings → Apps → '
            'JalMitra → Battery சென்று "No restrictions" தேர்ந்தெடுங்கள், '
            'இல்லையெனில் அலாரம் தடுக்கப்படலாம்.',
  };
}
