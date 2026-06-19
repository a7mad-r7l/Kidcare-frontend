import 'package:get/get.dart';

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    // ==========================================================
    // 1. ENGLISH LOCALE (en_US)
    // ==========================================================
    'en_US': {
      'Home': 'Home',
      'Appointments': 'Appointments',
      'Records': 'Records',
      'More': 'More',
      'Next': 'Next',
      'Or': 'Or',
      'Cancel': 'Cancel',
      'Delete': 'Delete',
      'Save': 'Save',
      'Done': 'Done',
      'Verify': 'Verify',
      'Today': 'Today',
      'version': 'Version',

      // --- Login View ---
      'Welcome Back': 'Welcome Back',
      'Phone Number': 'Phone Number',
      'Password': 'Password',
      'Forgot Password?': 'Forgot Password?',
      'Login': 'Login',
      'Create New Account': 'Create New Account',
      'Have a clinic file? ': 'Have a clinic file? ',
      'Activate account': 'Activate account',
      'LogIn': 'LogIn',

      // --- Sign Up View ---
      'Create your account to benefit from our services':
          'Create your account to benefit from our services',
      'Enter your name': 'Enter your name',
      'Name': 'Name',
      'Enter your last name': 'Enter your last name',
      'Last Name': 'Last Name',
      'Enter your email': 'Enter your email',
      'Email': 'Email',
      'Enter your phone number': 'Enter your phone number',
      'Phone': 'Phone',
      'Enter your address in detail': 'Enter your address in detail',
      'Address': 'Address',
      'Enter your password': 'Enter your password',
      'At least 8 characters with uppercase, lowercase and a number':
          'At least 8 characters with uppercase, lowercase and a number',
      'Enter your password again': 'Enter your password again',
      'Confirm Password': 'Confirm Password',
      'Create Account': 'Create Account',
      'Already have an account?': 'Already have an account?',

      //read more
      'About App': 'About App',
      'Pediatric Clinic Management': 'Pediatric Clinic Management System',
      'Our Vision': 'Our Vision',
      'Our Mission': 'Our Mission',
      'Key Features': 'Key Features',
      'Version 1.0.0': 'Version 1.0.0',
      'app_vision_desc': 'We aim to redefine pediatric healthcare by providing a seamless, integrated digital environment that bridges the gap between parents and specialized doctors, putting your child\'s health and comfort first.',

      'app_mission_desc': 'Empowering parents through a unified platform that allows them to easily create and manage medical profiles for all their children, book appointments with complete flexibility, and track health records safely and reliably anytime, anywhere.',

      'app_features_desc': '• Comprehensive Family Management: A main account with separate profiles for each child.\n• Smart & Fast Booking: Schedule medical appointments with a single click.\n• Real-Time Tracking: Monitor appointment status (Confirmed, Pending, Cancelled).\n• Secure Digital Payment: Multiple and reliable electronic payment options.\n• Eye-Friendly Design: Interfaces supporting both Dark and Light modes for the best user experience.',


      // --- Activation & OTP Views ---
      'Activate Account': 'Activate Account',
      'Enter your phone number registered at the clinic':
          'Enter your phone number registered at the clinic',
      'phone number': 'phone number',
      'Please enter your registered phone number':
          'Please enter your registered phone number',
      'Send Verification Code': 'Send Verification Code',
      'Verify Your Phone': 'Verify Your Phone',
      'Verify Your Phone Number': 'Verify Your Phone Number',
      'Verify Your Number': 'Verify Your Number',
      "Didn't receive the code?": "Didn't receive the code?",
      'Resend Code': 'Resend Code',
      'Resend in': 'Resend in',
      'Verify and Activate Account': 'Verify and Activate Account',
      'Create New Password': 'Create New Password',
      'Create a strong password to protect your account':
          'Create a strong password to protect your account',
      'New Password': 'New Password',
      'Password must contain:': 'Password must contain:',
      'At least 8 characters': 'At least 8 characters',
      'Set Password and Login': 'Set Password and Login',
      'The code is valid for ': 'The code is valid for ',
      ' minutes': ' minutes',
      'You can resend the code after the countdown ends':
          'You can resend the code after the countdown ends',
      'Change Phone Number': 'Change Phone Number',

      // --- Forgot Password ---
      "Don't worry, enter your phone number and we will send you a verification code.":
          "Don't worry, enter your phone number and we will send you a verification code.",
      'We sent a 4-digit code to': 'We sent a 4-digit code to',
      'Your new password must be different':
          'Your new password must be different',
      'Update Password': 'Update Password',
      'Password Updated!': 'Password Updated!',
      'Your password has been updated successfully. You can now log in with your new password.':
          'Your password has been updated successfully. You can now log in with your new password.',
      'Back to Login': 'Back to Login',

      // --- Home View ---
      'Welcome!': 'Welcome!',
      'Welcome back!': 'Welcome back!',
      'No children added yet': 'No children added yet',
      'Book New Appointment': 'Book New Appointment',
      'Departments': 'Departments',
      'General Pediatrics': 'General Pediatrics',
      'Dental Care': 'Dental Care',
      'Psychiatry': 'Psychiatry',
      'About the Clinic': 'About the Clinic',
      'We provide comprehensive healthcare for your children with the highest quality standards.':
          'We provide comprehensive healthcare for your children with the highest quality standards.',
      'Read More': 'Read More',
      'Vaccinations': 'Vaccinations',

      // --- Add Child & Child Profile ---
      'Child Profile': 'Child Profile',
      'Add New Child': 'Add New Child',
      'First Name': 'First Name',
      'Enter first name': 'Enter first name',
      'Enter last name': 'Enter last name',
      'Gender': 'Gender',
      'Female': 'female',
      'Male': 'male',
      'Birth Date': 'Birth Date',
      'Select birth date': 'Select birth date',
      'Blood Type': 'Blood Type',
      'Select blood type': 'Select blood type',
      'Medical History': 'Medical History',
      "Enter child's medical history": "Enter child's medical history",
      'Allergies': 'Allergies',
      'Enter any allergies the child has': 'Enter any allergies the child has',
      'Height': 'Height',
      'Weight': 'Weight',
      'Vaccination Record': 'Vaccination Record',
      'Medical Prescriptions': 'Medical Prescriptions',
      'Delete Child Profile': 'Delete Child Profile',
      'Delete Child': 'Delete Child',
      'Are you sure you want to delete this child profile? This action cannot be undone.':
          'Are you sure you want to delete this child profile? This action cannot be undone.',
      'Age': 'Age',
      'Child age cannot exceed 6 years.': 'Child age cannot exceed 6 years.',

      // --- Appointments List View ---
      'My Appointments': 'My Appointments',
      'Child Appointments': 'Child Appointments',
      'Upcoming': 'Upcoming',
      'Past': 'Past',
      'No appointments found': 'No appointments found',
      'Upcoming Appointments': 'Upcoming Appointments',

      // --- Booking Flow ---
      'Choose Doctor': 'Choose Doctor',
      'No departments available': 'No departments available',
      'Pick a department above to see the doctors.':
          'Pick a department above to see the doctors.',
      'No doctors available in this department.':
          'No doctors available in this department.',
      'Specialist': 'Specialist',
      'rating': 'rating',
      'Choose Child': 'Choose Child',
      "You haven't added any children yet.":
          "You haven't added any children yet.",
      'years': 'years',
      'Pick Date & Time': 'Pick Date & Time',
      'Available Times': 'Available Times',
      'Pick a date to see available times.':
          'Pick a date to see available times.',
      'No times available for this date.': 'No times available for this date.',
      'Book Appointment': 'Book Appointment',
      'Appointment Booked!': 'Appointment Booked!',
      'Your appointment has been confirmed.\nSee you soon!':
          'Your appointment has been confirmed.\nSee you soon!',
      'Dr. ': 'Dr. ',

      // --- Payment & Checkout ---
      'Finalize Appointment': 'Finalize Appointment',
      'Pay Online Now': 'Pay Online Now',
      'Pay online to confirm booking': 'Pay online to confirm booking',
      'Confirm & Proceed': 'Confirm & Proceed',
      'Review & Pay': 'Review & Pay',
      'Date & Time': 'Date & Time',
      'Consultation Fee': 'Consultation Fee',
      'Total': 'Total',
      'Choose how to pay': 'Choose how to pay',
      'Mada': 'Mada',
      'Credit Card (Visa/Mastercard)': 'Credit Card (Visa/Mastercard)',
      'Apple Pay': 'Apple Pay',
      'STC Pay': 'STC Pay',
      'Payment Successful!': 'Payment Successful!',
      'Your appointment is confirmed': 'Your appointment is confirmed',
      'Doctor': 'Doctor',
      'Child': 'Child',
      'Date': 'Date',
      'Time': 'Time',
      'Amount': 'Amount',
      'Transaction ID': 'Transaction ID',
      'Back to Home': 'Back to Home',
      'View My Appointments': 'View My Appointments',
      'Pay ': 'Pay ',

      // --- New Additions (Add Child, Appointments, Session) ---
      'Invalid Age': 'Invalid Age',
      'No medical history': 'No medical history',
      'No allergies': 'No allergies',
      'Unknown Child': 'Unknown Child',
      'Unknown Doctor': 'Unknown Doctor',
      'Patient': 'Patient',
      'General': 'General',
      'Session Expired': 'Session Expired',
      'Please login again to continue.': 'Please login again to continue.',
      'Failed to load appointment data.': 'Failed to load appointment data.',

      // --- Appointment Status ---
      'Confirmed': 'Confirmed',
      'Pending': 'Pending',
      'Cancelled': 'Cancelled',
      'Canceled': 'Canceled', // تحسباً لاختلاف الإملاء من الباك إند
      'Completed': 'Completed',

      // --- Profile & Settings ---
      'Personal Profile': 'Personal Profile',
      'Number of Children': 'Number of Children',
      'Logout': 'Logout',
      'settings': 'Settings',
      'language': 'Language',
      'change_language': 'Change Language',
      'theme': 'Theme',
      'light_mode': 'Light Mode',
      'support_and_more': 'Support & More',
      'help_center': 'Help Center',
      'faq_and_support': 'FAQs and Support',
      'app_rating': 'Rate App',
      'share_your_opinion': 'Share your opinion with us',
      'about_app': 'About App',
      'Delete account': 'Delete account',
      'account': 'Account',
      'preferences': 'Preferences',
      'Notice': 'Notice',
      'Please enter phone number': 'Please enter phone number',
      'Phone number must be 12 numbers (e.g., 9639XXXXXXXX)':
          'Phone number must be 12 numbers (e.g., 9639XXXXXXXX)',
      'Success': 'Success',
      'Verification code resent successfully':
          'Verification code resent successfully',
      'Check Code': 'Check Code',
      'Please enter OTP': 'Please enter the verification code',
      'Please enter the 4-digit code correctly':
          'Please enter the 4-digit code correctly',
      'Passwords do not match': 'Passwords do not match',
      'Weak Password': 'Weak Password',
      'Password must be at least 8 characters long':
          'Password must be at least 8 characters long',
      'Account activated successfully': 'Account activated successfully',
      'Please enter a valid phone number': 'Please enter a valid phone number',
      'Please enter the 4-digit code': 'Please enter the 4-digit code',
      'Password Updated Successfully!': 'Password Updated Successfully!',
      'Invalid Phone Number': 'Invalid Phone Number',
      'Welcome Back,': 'Welcome Back,',
      'Required': 'Required',
      'Please enter the verification code':
          'Please enter the verification code',
      'Invalid Code': 'Invalid Code',
      'Please enter the complete 4-digit code':
          'Please enter the complete 4-digit code',
      'Phone verified successfully!': 'Phone verified successfully!',
      'Code resent successfully!': 'Code resent successfully!',
      'Something went wrong. Please try again.':
          'Something went wrong. Please try again.',
      'Incorrect phone number or password.':
          'Incorrect phone number or password.',
      'No Internet connection. Please check your network.':
          'No Internet connection. Please check your network.',
      'Request timed out. Please try again.':
          'Request timed out. Please try again.',
      'Error': 'Error',
      'Info': 'Info',
      'Child deleted successfully!': 'Child deleted successfully!',
      'Please enter first and last name': 'Please enter first and last name',
      'Please select birth date': 'Please select birth date',
      'Please select blood type': 'Please select blood type',
      'Child added successfully!': 'Child added successfully!',
      'Failed to load profile': 'Failed to load profile',
      'Error Loading Details': 'Error Loading Details',
      'No appointment data found to process':
          'No appointment data found to process',
      'KidCare Clinic': 'KidCare Clinic',
      'Payment Error': 'Payment Error',
      'Payment Cancelled': 'Payment Cancelled',
      'User cancelled the payment': 'User cancelled the payment',
      'An unexpected error occurred': 'An unexpected error occurred',
      'favorite_doctors': 'Favorite Doctors',
      'view_favorite_doctors': 'View your favorite doctors',
      'Session expired. Please login again.':
          'Session expired. Please login again.',
      'Weight (kg)': 'Weight (kg)',
      'Height (cm)': 'Height (cm)',
      'Record Date': 'Record Date',
      'Save Measurement': 'Save Measurement',
      'Please enter valid weight and height':
          'Please enter valid weight and height',
      'Measurement saved successfully': 'Measurement saved successfully',
      'Are you sure you want to delete this record?':
          'Are you sure you want to delete this record?',
      'Growth History': 'Growth History',
      'Age (Months)': 'Age (Months)',
      'Ideal Weight (WHO)': 'Ideal Weight (WHO)',
      'Max Limit (WHO)': 'Max Limit (WHO)',
      'Min Limit (WHO)': 'Min Limit (WHO)',
      'Child Growth Chart': 'Child Growth Chart',
      'Status: ': 'Status: ',
      'Current Weight': 'Current Weight',
      'Current Height': 'Current Height',
      'Months': 'Months',
      'Growth Chart & Weight': 'Growth Chart & Weight',
      'Appointments & Files': 'Appointments & Files',
      'Medical Assessment': 'Medical Assessment',
      'Needs Review': 'Needs Review',
      'Add Measurement': 'Add Measurement',
      'Notifications': 'Notifications',
      'No notifications found': 'No notifications found',
    },

    // ==========================================================
    // 2. ARABIC LOCALE (ar_SA)
    // ==========================================================
    'ar_SA': {
      'Home': 'الرئيسية',
      'Appointments': 'المواعيد',
      'Records': 'الملفات',
      'More': 'المزيد',
      'Next': 'التالي',
      'Or': 'أو',
      'Cancel': 'إلغاء',
      'Delete': 'حذف',
      'Save': 'حفظ',
      'Done': 'تم',
      'Verify': 'تحقق',
      'Today': 'اليوم',
      'version': 'الإصدار',

      // --- Login View ---
      'Welcome Back': 'مرحباً بك مجدداً',
      'Phone Number': 'رقم الهاتف',
      'Password': 'كلمة المرور',
      'Forgot Password?': 'نسيت كلمة المرور؟',
      'Login': 'تسجيل الدخول',
      'Create New Account': 'إنشاء حساب جديد',
      'Have a clinic file? ': 'لديك ملف بالعيادة؟ ',
      'Activate account': 'تفعيل الحساب',
      'LogIn': 'تسجيل الدخول',

      // --- Sign Up View ---
      'Create your account to benefit from our services':
          'أنشئ حسابك للاستفادة من خدماتنا',
      'Enter your name': 'أدخل اسمك',
      'Name': 'الاسم',
      'Enter your last name': 'أدخل اسم العائلة',
      'Last Name': 'اسم العائلة',
      'Enter your email': 'أدخل بريدك الإلكتروني',
      'Email': 'البريد الإلكتروني',
      'Enter your phone number': 'أدخل رقم هاتفك',
      'Phone': 'الهاتف',
      'Enter your address in detail': 'أدخل عنوانك بالتفصيل',
      'Address': 'العنوان',
      'Enter your password': 'أدخل كلمة المرور',
      'At least 8 characters with uppercase, lowercase and a number':
          '8 أحرف على الأقل، تتضمن أحرف كبيرة وصغيرة ورقم',
      'Enter your password again': 'أدخل كلمة المرور مرة أخرى',
      'Confirm Password': 'تأكيد كلمة المرور',
      'Create Account': 'إنشاء الحساب',
      'Already have an account?': 'لديك حساب بالفعل؟',

      // --- Activation & OTP Views ---
      'Activate Account': 'تفعيل الحساب',
      'Enter your phone number registered at the clinic':
          'أدخل رقم هاتفك المسجل في العيادة',
      'phone number': 'رقم الهاتف',
      'Please enter your registered phone number':
          'يرجى إدخال رقم هاتفك المسجل',
      'Send Verification Code': 'إرسال رمز التحقق',
      'Verify Your Phone': 'تحقق من رقم الهاتف',
      'Verify Your Phone Number': 'تحقق من رقم الهاتف',
      'Verify Your Number': 'تحقق من رقمك',
      "Didn't receive the code?": "لم يصلك الرمز؟",
      'Resend Code': 'إعادة إرسال الرمز',
      'Resend in': 'إعادة الإرسال خلال',
      'Verify and Activate Account': 'تحقق وفعل الحساب',
      'Create New Password': 'إنشاء كلمة مرور جديدة',
      'Create a strong password to protect your account':
          'أنشئ كلمة مرور قوية لحماية حسابك',
      'New Password': 'كلمة المرور الجديدة',
      'Password must contain:': 'يجب أن تحتوي كلمة المرور على:',
      'At least 8 characters': '8 أحرف على الأقل',
      'Set Password and Login': 'تعيين كلمة المرور وتسجيل الدخول',
      'The code is valid for ': 'الرمز صالح لمدة ',
      ' minutes': ' دقائق',
      'You can resend the code after the countdown ends':
          'يمكنك إعادة إرسال الرمز بعد انتهاء العداد',
      'Change Phone Number': 'تغيير رقم الهاتف',

      // --- Forgot Password ---
      "Don't worry, enter your phone number and we will send you a verification code.":
          "لا تقلق، أدخل رقم هاتفك وسنرسل لك رمز التحقق.",
      'We sent a 4-digit code to': 'أرسلنا رمزاً من 4 أرقام إلى',
      'Your new password must be different':
          'يجب أن تكون كلمة المرور جديدة ومختلفة',
      'Update Password': 'تحديث كلمة المرور',
      'Password Updated!': 'تم تحديث كلمة المرور!',
      'Your password has been updated successfully. You can now log in with your new password.':
          'تم تحديث كلمة المرور بنجاح. يمكنك الآن تسجيل الدخول بكلمة المرور الجديدة.',
      'Back to Login': 'العودة لتسجيل الدخول',

      // --- Home View ---
      'Welcome!': 'مرحباً بك!',
      'Welcome back!': 'مرحباً بك مجدداً!',
      'No children added yet': 'لم يتم إضافة أطفال بعد',
      'Book New Appointment': 'حجز موعد جديد',
      'Departments': 'الأقسام',
      'General Pediatrics': 'طب الأطفال العام',
      'Dental Care': 'عناية الأسنان',
      'Psychiatry': 'الطب النفسي',
      'About the Clinic': 'عن العيادة',
      'We provide comprehensive healthcare for your children with the highest quality standards.':
          'نقدم رعاية صحية شاملة لأطفالك بأعلى معايير الجودة.',
      'Read More': 'اقرأ المزيد',
      'Vaccinations': 'اللقاحات',

      //read more
      'About App': 'عن التطبيق',
      'Pediatric Clinic Management': 'نظام إدارة عيادة الأطفال',
      'Our Vision': 'رؤيتنا',
      'Our Mission': 'رسالتنا',
      'Key Features': 'أبرز المميزات',
      'Version 1.0.0': 'الإصدار 1.0.0',
      'app_vision_desc': 'نسعى لإعادة صياغة تجربة الرعاية الصحية للأطفال من خلال تقديم بيئة رقمية متكاملة وسهلة الاستخدام، تقرب المسافات بين الآباء والأطباء المتخصصين وتضع راحة وصحة طفلك في المقام الأول.',

      'app_mission_desc': 'تمكين الآباء والأمهات من خلال منصة موحدة تتيح لهم إنشاء وإدارة الملفات الطبية لجميع أطفالهم بسهولة، حجز المواعيد بمرونة تامة، ومتابعة السجلات الصحية بكل أمان وموثوقية في أي وقت ومن أي مكان.',

      'app_features_desc': '• إدارة عائلية متكاملة: حساب أساسي يضم ملفات منفصلة لكل طفل.\n• حجز ذكي وسريع: جدولة المواعيد الطبية بضغطة زر.\n• تتبع حي للمواعيد: متابعة حالة الحجز (مؤكد، قيد الانتظار، ملغي).\n• دفع إلكتروني آمن: خيارات دفع متعددة وموثوقة.\n• تصميم مريح للعين: واجهات تدعم الوضعين الليلي والنهاري لضمان أفضل تجربة استخدام.',


      // --- Add Child & Child Profile ---
      'Child Profile': 'ملف الطفل',
      'Add New Child': 'إضافة طفل جديد',
      'First Name': 'الاسم الأول',
      'Enter first name': 'أدخل الاسم الأول',
      'Enter last name': 'أدخل اسم العائلة',
      'Gender': 'الجنس',
      'famale': 'أنثى',
      'male': 'ذكر',
      'Birth Date': 'تاريخ الميلاد',
      'Select birth date': 'اختر تاريخ الميلاد',
      'Blood Type': 'فصيلة الدم',
      'Select blood type': 'اختر فصيلة الدم',
      'Medical History': 'التاريخ الطبي',
      "Enter child's medical history": "أدخل التاريخ الطبي للطفل",
      'Allergies': 'الحساسية',
      'Enter any allergies the child has': 'أدخل أي حساسية يعاني منها الطفل',
      'Height': 'الطول',
      'Weight': 'الوزن',
      'Vaccination Record': 'سجل اللقاحات',
      'Medical Prescriptions': 'الوصفات الطبية',
      'Delete Child Profile': 'حذف ملف الطفل',
      'Delete Child': 'حذف الطفل',
      'Are you sure you want to delete this child profile? This action cannot be undone.':
          'هل أنت متأكد أنك تريد حذف ملف هذا الطفل؟ لا يمكن التراجع عن هذا الإجراء.',
      'Age': 'العمر',
      'Child age cannot exceed 6 years.':
          'عمر الطفل لا يمكن أن يتجاوز 6 سنوات.',

      // --- Appointments List View ---
      'My Appointments': 'مواعيدي',
      'Child Appointments': 'مواعيد الطفل',
      'Upcoming': 'القادمة',
      'Past': 'السابقة',
      'No appointments found': 'لا توجد مواعيد',
      'Upcoming Appointments': 'المواعيد القادمة',

      // --- Booking Flow ---
      'Choose Doctor': 'اختر الطبيب',
      'No departments available': 'لا توجد أقسام متاحة',
      'Pick a department above to see the doctors.':
          'اختر قسماً من الأعلى لرؤية الأطباء.',
      'No doctors available in this department.':
          'لا يوجد أطباء متاحين في هذا القسم.',
      'Specialist': 'أخصائي',
      'rating': 'تقييم',
      'Choose Child': 'اختر الطفل',
      "You haven't added any children yet.": "لم تقم بإضافة أي أطفال بعد.",
      'years': ' سنوات',
      'Pick Date & Time': 'اختر التاريخ والوقت',
      'Available Times': 'الأوقات المتاحة',
      'Pick a date to see available times.':
          'اختر تاريخاً لرؤية الأوقات المتاحة.',
      'No times available for this date.': 'لا توجد أوقات متاح في هذا التاريخ.',
      'Book Appointment': 'تأكيد الحجز',
      'Appointment Booked!': 'تم حجز الموعد!',
      'Your appointment has been confirmed.\nSee you soon!':
          'تم تأكيد موعدك.\nنراك قريباً!',
      'Dr. ': 'د. ',

      // --- Payment & Checkout ---
      'Finalize Appointment': 'إتمام الحجز',
      'Pay Online Now': 'الدفع الآن إلكترونياً',
      'Pay online to confirm booking': 'ادفع إلكترونياً لتأكيد الحجز',
      'Confirm & Proceed': 'تأكيد ومتابعة',
      'Review & Pay': 'مراجعة ودفع',
      'Date & Time': 'التاريخ والوقت',
      'Consultation Fee': 'رسوم الكشف',
      'Total': 'الإجمالي',
      'Choose how to pay': 'اختر طريقة الدفع',
      'Mada': 'مدى',
      'Credit Card (Visa/Mastercard)': 'بطاقة ائتمان (فيزا/ماستركارد)',
      'Apple Pay': 'أبل باي',
      'STC Pay': 'إس تي سي باي',
      'Payment Successful!': 'تمت عملية الدفع بنجاح!',
      'Your appointment is confirmed': 'تم تأكيد موعدك',
      'Doctor': 'الطبيب',
      'Child': 'الطفل',
      'Date': 'التاريخ',
      'Time': 'الوقت',
      'Amount': 'المبلغ',
      'Transaction ID': 'رقم العملية',
      'Back to Home': 'العودة للرئيسية',
      'View My Appointments': 'عرض مواعيدي',
      'Pay ': 'دفع ',

      // --- New Additions (Add Child, Appointments, Session) ---
      'Invalid Age': 'عمر غير مقبول',
      'No medical history': 'لا يوجد سجل طبي',
      'No allergies': 'لا يعاني من حساسية',
      'Unknown Child': 'طفل غير معروف',
      'Unknown Doctor': 'طبيب غير معروف',
      'Patient': 'المريض',
      'General': 'عام',
      'Session Expired': 'انتهت الجلسة',
      'Please login again to continue.': 'يرجى تسجيل الدخول مرة أخرى للمتابعة.',
      'Failed to load appointment data.': 'فشل في تحميل بيانات الموعد.',

      // --- Appointment Status ---
      'Confirmed': 'مؤكد',
      'Pending': 'قيد الانتظار',
      'Cancelled': 'ملغي',
      'Canceled': 'ملغي',
      'Completed': 'تم',

      // --- Profile & Settings ---
      'Personal Profile': 'الملف الشخصي',
      'Number of Children': 'عدد الأطفال',
      'Logout': 'تسجيل الخروج',
      'settings': 'الإعدادات',
      'language': 'اللغة',
      'change_language': 'تغيير اللغة',
      'theme': 'المظهر',
      'light_mode': 'الوضع الفاتح',
      'support_and_more': 'الدعم والمزيد',
      'help_center': 'مركز المساعدة',
      'faq_and_support': 'الأسئلة الشائعة والدعم',
      'app_rating': 'تقييم التطبيق',
      'share_your_opinion': 'شاركنا رأيك',
      'about_app': 'عن التطبيق',
      'Delete account': 'حذف الحساب',
      'account': 'الحساب',
      'preferences': 'التفضيلات',
      'Required Fields': 'الحقول المطلوبة',
      'Please fill in all fields': 'يرجى ملء جميع الحقول',
      'Notice': 'تنبيه',
      'Please enter phone number': 'يرجى إدخال رقم الهاتف',
      'Phone number must be 12 numbers (e.g., 9639XXXXXXXX)':
          'يجب أن يتكون رقم الهاتف من 12 رقماً (مثال: 9639XXXXXXXX)',
      'Success': 'نجاح',
      'Verification code resent successfully':
          'تم إعادة إرسال رمز التحقق بنجاح',
      'Check Code': 'التحقق من الرمز',
      'Please enter OTP': 'يرجى إدخال رمز التحقق',
      'Please enter the 4-digit code correctly':
          'يرجى إدخال الرمز المكون من 4 أرقام بشكل صحيح',
      'Passwords do not match': 'كلمتا المرور غير متطابقتين',
      'Weak Password': 'كلمة مرور ضعيفة',
      'Password must be at least 8 characters long':
          'يجب أن تتكون كلمة المرور من 8 أحرف على الأقل',
      'Account activated successfully': 'تم تفعيل الحساب بنجاح',
      'Please enter a valid phone number': 'يرجى إدخال رقم هاتف صحيح',
      'Please enter the 4-digit code': 'يرجى إدخال الرمز المكون من 4 أرقام',
      'Password Updated Successfully!': 'تم تحديث كلمة المرور بنجاح!',
      'Invalid Phone Number': 'رقم هاتف غير صحيح',
      'Welcome Back,': 'مرحباً بك مجدداً،',
      'Required': 'مطلوب',
      'Please enter the verification code': 'يرجى إدخال رمز التحقق',
      'Invalid Code': 'رمز غير صحيح',
      'Please enter the complete 4-digit code':
          'يرجى إدخال رمز التحقق كاملاً المكون من 4 أرقام',
      'Phone verified successfully!': 'تم التحقق من رقم الهاتف بنجاح!',
      'Code resent successfully!': 'تم إعادة إرسال الرمز بنجاح!',
      'Something went wrong. Please try again.':
          'حدث خطأ ما، يرجى المحاولة مرة أخرى.',
      'Incorrect phone number or password.':
          'رقم الهاتف أو كلمة المرور غير صحيحة.',
      'No Internet connection. Please check your network.':
          'لا يوجد اتصال بالإنترنت، يرجى التحقق من الشبكة.',
      'Request timed out. Please try again.':
          'انتهت مهلة الطلب، يرجى المحاولة مجدداً.',
      'Error': 'خطأ',
      'Info': 'معلومات',
      'Child deleted successfully!': 'تم حذف ملف الطفل بنجاح!',
      'Please enter first and last name': 'يرجى إدخال الاسم الأول واسم العائلة',
      'Please select birth date': 'يرجى تحديد تاريخ الميلاد',
      'Please select blood type': 'يرجى اختيار فصيلة الدم',
      'Child added successfully!': 'تم إضافة الطفل بنجاح!',
      'Failed to load profile': 'فشل في تحميل بيانات الملف الشخصي',
      'Error Loading Details': 'خطأ في تحميل التفاصيل',
      'No appointment data found to process':
          'لم يتم العثور على بيانات للموعد لإتمام العملية',
      'KidCare Clinic': 'عيادة كيد كير',
      'Payment Error': 'خطأ في عملية الدفع',
      'Payment Cancelled': 'تم إلغاء الدفع',
      'User cancelled the payment': 'قام المستخدم بإلغاء عملية الدفع',
      'An unexpected error occurred': 'حدث خطأ غير متوقع',
      'favorite_doctors': 'الأطباء المفضلون',
      'view_favorite_doctors': 'عرض قائمة أطبائك المفضلين',
      'Session expired. Please login again.':
          'انتهت صلاحية الجلسة. يرجى تسجيل الدخول مجدداً.',
      'Weight (kg)': 'الوزن (كجم)',
      'Height (cm)': 'الطول (سم)',
      'Record Date': 'تاريخ القياس',
      'Save Measurement': 'حفظ القياس',
      'Please enter valid weight and height': 'يرجى إدخال وزن وطول صحيحين',
      'Measurement saved successfully': 'تم حفظ القياس بنجاح',
      'Are you sure you want to delete this record?':
          'هل أنت متأكد من حذف هذا السجل؟',
      'Growth History': 'سجلات النمو',
      'Age (Months)': 'العمر (شهر)',
      'Ideal Weight (WHO)': 'المعدل المثالي (WHO)',
      'Max Limit (WHO)': 'الحد الأقصى للوزن',
      'Min Limit (WHO)': 'الحد الأدنى للوزن',
      'Child Growth Chart': 'منحنى النمو والوزن',
      'Status: ': 'الحالة: ',
      'Current Weight': 'الوزن الحالي',
      'Current Height': 'الطول الحالي',
      'Months': 'شهر',
      'Growth Chart & Weight': 'منحنى النمو والوزن',
      'Appointments & Files': 'المواعيد والملفات',
      'Medical Assessment': 'التقييم الطبي المفصل',
      'Needs Review': 'يحتاج متابعة',
      'Add Measurement': 'إضافة قياس',
      'Notifications': 'الإشعارات',
      'No notifications found': 'لا توجد إشعارات حالياً',
    },
  };
}
