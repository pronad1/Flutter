import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart';

class EnhancedChatbotService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;
  
  // Conversation memory (protected for subclasses)
  final List<Map<String, String>> conversationHistory = [];
  String? lastTopic;
  
  // Synonyms dictionary for better understanding (protected for subclass)
  final Map<String, List<String>> synonyms = {
    'donate': ['donate', 'donation', 'donating', 'dontion', 'give', 'give away', 'contribute', 'share', 'post'],
    'request': ['request', 'ask for', 'need', 'want', 'looking for', 'seeking', 'require', 'requist'],
    'search': ['search', 'find', 'look for', 'browse', 'explore', 'discover', 'serch'],
    'help': ['help', 'assist', 'support', 'guide', 'tutorial', 'how'],
    'problem': ['problem', 'issue', 'error', 'bug', 'not working', 'broken', 'fail', 'problm'],
    'profile': ['profile', 'account', 'settings', 'info', 'information', 'profil'],
    'rating': ['rating', 'review', 'feedback', 'rate', 'star', 'ratig'],
    'item': ['item', 'product', 'thing', 'stuff', 'goods', 'itm'],
    'available': ['available', 'free', 'open', 'accessible', 'ready', 'availble'],
    'category': ['category', 'type', 'kind', 'classification', 'categry'],
    'edit': ['edit', 'change', 'modify', 'update', 'alter', 'edt'],
    'delete': ['delete', 'remove', 'cancel', 'erase', 'delet'],
    'contact': ['contact', 'message', 'chat', 'talk', 'reach', 'communicate', 'contact', 'mesage'],
    'number': ['number', 'mobile', 'phone', 'contact number', 'phone number', 'numer'],
  };
  
  Future<String> getResponse(String userMessage) async {
    await Future.delayed(const Duration(milliseconds: 1500));
    
    final message = userMessage.toLowerCase().trim();
    final currentUser = auth.currentUser;
    
    // Add to conversation history
    conversationHistory.add({
      'user': userMessage,
      'timestamp': DateTime.now().toString(),
    });
    
    // Keep only last 10 messages
    if (conversationHistory.length > 10) {
      conversationHistory.removeAt(0);
    }
    
    // Check if follow-up question
    if (isFollowUpQuestion(message)) {
      return getFollowUpResponse(message);
    }
    
    // Try fuzzy matching for better understanding
    final intent = detectIntent(message);
    
    // Handle based on intent
    switch (intent) {
      case 'greeting':
        return handleGreeting(currentUser);
      case 'thanks':
        return handleThanks();
      case 'donate':
        lastTopic = 'donate';
        return getDonationHelp(message);
      case 'request':
        lastTopic = 'request';
        return getRequestHelp(message);
      case 'search':
        lastTopic = 'search';
        return getSearchHelp();
      case 'profile':
        lastTopic = 'profile';
        return getProfileHelp();
      case 'rating':
        lastTopic = 'rating';
        return getRatingHelp();
      case 'contact':
        lastTopic = 'contact';
        return getContactHelp(message);
      case 'problem':
        lastTopic = 'problem';
        return getTechnicalHelp(message);
      case 'data':
        return await handleDataRequest(message, currentUser);
      default:
        return handleUnknown(message);
    }
  }
  
  // Fuzzy matching to check if message contains any synonym
  bool fuzzyContains(String message, String category) {
    if (!synonyms.containsKey(category)) return false;
    
    for (var synonym in synonyms[category]!) {
      // Use fuzzy matching for typos
      if (ratio(message, synonym) > 70) {
        return true;
      }
      // Also check direct contains
      if (message.contains(synonym)) {
        return true;
      }
    }
    return false;
  }
  
  // Detect user intent from message (protected for subclass)
  String detectIntent(String message) {
    // Greetings
    if (message.contains('hi') || 
        message.contains('hello') ||
        message.contains('hey') ||
        message.contains('good morning') ||
        message.contains('good afternoon') ||
        message.contains('good evening')) {
      return 'greeting';
    }
    
    // Thanks
    if (message.contains('thank') || message.contains('thanks')) {
      return 'thanks';
    }
    
    // Data requests
    if (message.contains('my ') || 
        message.contains('show') ||
        message.contains('how many') ||
        message.contains('total') ||
        message.contains('count') ||
        message.contains('recent') ||
        message.contains('latest') ||
        message.contains('statistics') ||
        message.contains('stats')) {
      return 'data';
    }
    
    // Problems
    if (fuzzyContains(message, 'problem')) {
      return 'problem';
    }
    
    // Donation related
    if (fuzzyContains(message, 'donate')) {
      return 'donate';
    }
    
    // Request related
    if (fuzzyContains(message, 'request')) {
      return 'request';
    }
    
    // Search related
    if (fuzzyContains(message, 'search')) {
      return 'search';
    }
    
    // Profile related
    if (fuzzyContains(message, 'profile')) {
      return 'profile';
    }
    
    // Rating related
    if (fuzzyContains(message, 'rating')) {
      return 'rating';
    }
    
    // Contact/Messaging related
    if (fuzzyContains(message, 'contact') || 
        message.contains('message') || 
        message.contains('chat') ||
        message.contains('talk to') ||
        message.contains('reach')) {
      return 'contact';
    }
    
    return 'unknown';
  }
  
  bool isFollowUpQuestion(String message) {
    final followUpStarters = ['more', 'also', 'what about', 'how about', 'and', 'else'];
    return followUpStarters.any((starter) => message.startsWith(starter)) && 
           lastTopic != null;
  }
  
  String getFollowUpResponse(String message) {
    if (lastTopic == 'donate') {
      if (message.contains('edit') || message.contains('change')) {
        return '✏️ **Edit Donations:**\n\n'
            '1. Go to Profile → Donor Dashboard\n'
            '2. Find your item\n'
            '3. Tap edit icon (✏️)\n'
            '4. Make changes\n'
            '5. Tap "Save Changes"\n\n'
            '💡 You can edit title, description, photos, category, and condition!';
      }
      if (message.contains('delete') || message.contains('remove')) {
        return '🗑️ **Delete Donations:**\n\n'
            '1. Go to Profile → Donor Dashboard\n'
            '2. Find your item\n'
            '3. Tap delete icon (🗑️)\n'
            '4. Confirm deletion\n\n'
            '⚠️ **Note:** You can\'t delete items with approved requests!';
      }
    }
    
    if (lastTopic == 'request') {
      if (message.contains('cancel')) {
        return '❌ **Cancel Requests:**\n\n'
            '1. Go to Profile → Seeker Dashboard\n'
            '2. Find pending request\n'
            '3. Tap "Cancel Request"\n'
            '4. Confirm cancellation\n\n'
            '💡 This frees up your monthly quota!';
      }
    }
    
    return 'Could you be more specific? I\'m here to help!';
  }
  
  String handleGreeting(User? user) {
    final hour = DateTime.now().hour;
    String greeting = 'Hello';
    if (hour < 12) greeting = 'Good morning';
    else if (hour < 17) greeting = 'Good afternoon';
    else if (hour < 21) greeting = 'Good evening';
    
    final name = user?.displayName?.split(' ').first ?? 'there';
    
    return '$greeting $name! 👋\n\n'
        'I\'m your ReuseHub AI Assistant. I can help you with:\n\n'
        '📦 Donating items\n'
        '🙋 Requesting items\n'
        '🔍 Searching items\n'
        '👤 Profile & settings\n'
        '⭐ Ratings & reviews\n'
        '🔧 Technical support\n\n'
        'What would you like to know?';
  }
  
  String handleThanks() {
    final responses = [
      '😊 You\'re welcome! Feel free to ask anything else.',
      '😊 Happy to help! Anything else you need?',
      '😊 My pleasure! Let me know if you have more questions.',
    ];
    return responses[DateTime.now().millisecond % responses.length];
  }
  
  String getDonationHelp(String message) {
    if (message.contains('how') || message.contains('post') || message.contains('create')) {
      return '📦 **How to Donate Items:**\n\n'
          '**Step-by-Step Guide:**\n'
          '1. Go to **Profile** tab\n'
          '2. Tap "Post a new donation" button\n'
          '3. Fill in item details:\n'
          '   • Title (clear & descriptive)\n'
          '   • Description (condition, features)\n'
          '   • Upload photos (up to 5)\n'
          '4. Choose category (20+ options)\n'
          '5. Select condition level\n'
          '6. Add pickup address\n'
          '7. Tap "Post Item"\n\n'
          '💡 **Tips for Success:**\n'
          '• Use clear, well-lit photos\n'
          '• Be honest about condition\n'
          '• Include all relevant details\n'
          '• Set realistic pickup times\n\n'
          'Ask "how to edit?" for more help!';
    }
    
    if (message.contains('categories') || message.contains('category')) {
      return '📂 **Available Categories:**\n\n'
          '🖥️ Electronics & Appliances\n'
          '📚 Books & Media\n'
          '🪑 Furniture & Home\n'
          '👗 Clothing & Accessories\n'
          '⚽ Sports & Outdoors\n'
          '🎮 Toys & Games\n'
          '🔧 Tools & DIY\n'
          '🍳 Kitchen & Dining\n'
          '🎨 Art & Crafts\n'
          '🌱 Garden & Plants\n'
          '🚗 Automotive\n'
          '👶 Baby & Kids\n'
          '🐕 Pet Supplies\n'
          '🏥 Health & Beauty\n'
          '🎵 Musical Instruments\n'
          '📱 Phone & Accessories\n'
          '💻 Computer Parts\n'
          '📷 Camera & Photo\n'
          '🎓 Educational\n'
          '🏢 Office Supplies\n'
          '✨ Other\n\n'
          'Choose the best fit for your item!';
    }
    
    return '📦 **Donation Features:**\n\n'
        '• Post **unlimited** items\n'
        '• 20+ categories available\n'
        '• Edit or delete anytime\n'
        '• Track incoming requests\n'
        '• Get ratings from seekers\n'
        '• Manage via Donor Dashboard\n\n'
        'Ask "how to donate?" for detailed steps!';
  }
  
  String getRequestHelp(String message) {
    return '🙋 **How to Request Items:**\n\n'
        '**Step-by-Step Guide:**\n'
        '1. Browse items on **Home** or **Search**\n'
        '2. Find what you need\n'
        '3. Tap item to view details\n'
        '4. Check:\n'
        '   • Condition level\n'
        '   • Pickup address\n'
        '   • Donor ratings\n'
        '5. Tap "Request" button\n'
        '6. Wait for donor approval\n\n'
        '⚠️ **Monthly Limit:** 4 requests\n\n'
        '**Request Status:**\n'
        '🟡 Pending - Waiting for approval\n'
        '🟢 Approved - Ready for pickup!\n'
        '🔴 Rejected - Try other items\n\n'
        'Track all in **Seeker Dashboard**!\n\n'
        'Ask "cancel request?" for cancellation help.';
  }
  
  String getSearchHelp() {
    return '🔍 **How to Search Items:**\n\n'
        '**Basic Search:**\n'
        '1. Tap **Search** icon\n'
        '2. Type keywords (e.g., "laptop", "books")\n'
        '3. Browse results\n\n'
        '**Advanced Filters:**\n'
        '• **Category:** Select from 20+ options\n'
        '• **Condition:** From Brand New to Used\n'
        '• **Location:** Find items nearby\n\n'
        '**Smart Tips:**\n'
        '💡 Use specific keywords\n'
        '💡 Try category filters for better results\n'
        '💡 Check item condition before requesting\n'
        '💡 View donor ratings for reliability\n\n'
        '**Popular Searches:**\n'
        '📱 Electronics\n'
        '📚 Books\n'
        '🪑 Furniture\n'
        '👗 Clothing\n\n'
        'Happy searching! 🎉';
  }
  
  String getProfileHelp() {
    return '👤 **Profile Management:**\n\n'
        '**To Edit Your Profile:**\n'
        '1. Go to **Profile** tab\n'
        '2. Tap edit icon (✏️)\n'
        '3. Update:\n'
        '   • Profile photo\n'
        '   • Display name\n'
        '   • Bio (optional)\n'
        '4. Tap "Save Changes"\n\n'
        '**What Others See:**\n'
        '✅ Your name & photo\n'
        '✅ Your bio\n'
        '✅ Ratings & reviews\n'
        '✅ Email contact button\n\n'
        '**Privacy:**\n'
        '🔒 Email hidden (contact button only)\n'
        '🔒 Phone not visible\n'
        '🔒 Request history private\n\n'
        '💡 **Tip:** A complete profile builds trust!\n\n'
        'Keep your profile updated for better interactions! 😊';
  }
  
  String getContactHelp(String message) {
    // Check if asking about contacting another user
    if (message.contains('another') || message.contains('user') || 
        message.contains('donor') || message.contains('seeker') ||
        message.contains('someone') || message.contains('other')) {
      return '💬 **How to Contact Other Users:**\n\n'
          '**Chat with Donors:**\n'
          '1. Find an item you want\n'
          '2. Tap on the item\n'
          '3. Tap "Request" button\n'
          '4. After donor approves → Chat unlocked!\n'
          '5. Go to **Chat** tab → Start messaging\n\n'
          '**Chat with Seekers (as Donor):**\n'
          '1. Go to Profile → Donor Dashboard\n'
          '2. View your requests\n'
          '3. Approve a request\n'
          '4. Go to **Chat** tab\n'
          '5. Start conversation with seeker\n\n'
          '**Chat Features:**\n'
          '✅ Send text messages\n'
          '✅ Real-time notifications\n'
          '✅ Chat history saved\n'
          '✅ Arrange pickup details\n\n'
          '⚠️ **Important:** Chat only available after request approval!\n\n'
          '🔒 **Privacy:** Contact details are private - use in-app chat only!';
    }
    
    // General contact/messaging help
    return '💬 **Messaging System:**\n\n'
        '**How it Works:**\n'
        '1. Request an item (seeker)\n'
        '2. Owner approves request\n'
        '3. Chat unlocks automatically\n'
        '4. Both parties can message\n\n'
        '**Access Chats:**\n'
        'Go to **Chat** tab (bottom navigation)\n\n'
        '**What to Discuss:**\n'
        '• Pickup location & time\n'
        '• Item condition details\n'
        '• Coordination questions\n\n'
        '**Tips:**\n'
        '✅ Be polite and respectful\n'
        '✅ Respond promptly\n'
        '✅ Clear communication\n\n'
        'Ask "how to contact another user" for detailed steps! 💬';
  }
  
  String getRatingHelp() {
    return '⭐ **Rating System Guide:**\n\n'
        '**How to Rate Someone:**\n'
        '1. Visit their profile\n'
        '2. Scroll to "Leave a review" section\n'
        '3. Choose 1-5 stars:\n'
        '   ⭐ - Poor experience\n'
        '   ⭐⭐ - Below average\n'
        '   ⭐⭐⭐ - Average\n'
        '   ⭐⭐⭐⭐ - Good\n'
        '   ⭐⭐⭐⭐⭐ - Excellent!\n'
        '4. Write optional review text\n'
        '5. Tap "Submit Review"\n\n'
        '**Rating Criteria:**\n'
        '• Communication speed\n'
        '• Item condition accuracy\n'
        '• Reliability & punctuality\n'
        '• Overall experience\n\n'
        '**Tips:**\n'
        '💡 Be honest but respectful\n'
        '💡 Mention specific positives/negatives\n'
        '💡 Help others make informed decisions\n\n'
        '**Your ratings help build a trusted community!** 🌟';
  }
  
  String getTechnicalHelp(String message) {
    if (message.contains('login') || message.contains('password')) {
      return '🔐 **Login Issues Help:**\n\n'
          '**Forgot Password:**\n'
          '1. Tap "Forgot Password?" on login screen\n'
          '2. Enter your registered email\n'
          '3. Check inbox for reset link\n'
          '4. Click link & create new password\n'
          '5. Login with new password\n\n'
          '**Can\'t Log In:**\n'
          '• Verify email spelling is correct\n'
          '• Check if email is verified (check inbox)\n'
          '• Try "Forgot Password" to reset\n'
          '• Clear app cache and retry\n'
          '• Ensure stable internet connection\n\n'
          '**Email Not Received:**\n'
          '• Check spam/junk folder\n'
          '• Wait 5-10 minutes\n'
          '• Verify email address is correct\n'
          '• Contact support if still not received\n\n'
          'Still stuck? Contact support! 📧';
    }
    
    if (message.contains('photo') || message.contains('image') || message.contains('upload')) {
      return '📷 **Photo Upload Issues:**\n\n'
          '**If photos won\'t upload:**\n'
          '1. Check internet connection\n'
          '2. Ensure photo is under 5MB\n'
          '3. Use JPG or PNG format only\n'
          '4. Grant camera/gallery permissions\n'
          '5. Try restarting the app\n\n'
          '**Photo Tips:**\n'
          '✅ Clear, well-lit photos\n'
          '✅ Multiple angles (up to 5)\n'
          '✅ Show actual condition\n'
          '✅ Avoid blurry images\n\n'
          '**Permissions:**\n'
          'Go to Settings → Apps → ReuseHub → Permissions\n'
          'Enable: Camera & Storage\n\n'
          'Still having issues? Restart the app! 🔄';
    }
    
    if (message.contains('crash') || message.contains('freeze')) {
      return '💥 **App Crash/Freeze Help:**\n\n'
          '**Quick Fixes:**\n'
          '1. Force close and restart app\n'
          '2. Clear app cache:\n'
          '   Settings → Apps → ReuseHub → Clear Cache\n'
          '3. Update to latest version\n'
          '4. Check device storage (min 500MB free)\n'
          '5. Restart your device\n\n'
          '**Still Crashing?**\n'
          '• Update your device OS\n'
          '• Reinstall the app (data is safe in cloud)\n'
          '• Contact support with error details\n\n'
          '**Prevent Crashes:**\n'
          '• Keep app updated\n'
          '• Free up device storage\n'
          '• Close unused apps\n\n'
          'Need more help? Contact support! 🛠️';
    }
    
    return '🔧 **Technical Support:**\n\n'
        '**Common Issues:**\n'
        '• Login problems → "login help"\n'
        '• Email verification → Check spam folder\n'
        '• Photo uploads → "photo help"\n'
        '• App crashes → "crash help"\n'
        '• Slow loading → Check internet\n\n'
        '**Quick Troubleshooting:**\n'
        '1. Check internet connection\n'
        '2. Restart the app\n'
        '3. Clear app cache\n'
        '4. Update to latest version\n'
        '5. Restart your device\n\n'
        'Describe your specific problem for detailed help! 💬';
  }
  
  Future<String> handleDataRequest(String message, User? user) async {
    if (message.contains('my donation') || message.contains('my item') || message.contains('my dontion')) {
      return await getMyDonations(user);
    }
    
    if (message.contains('my request') || message.contains('my requist')) {
      return await getMyRequests(user);
    }
    
    // Handle rating queries (with typo tolerance)
    if (message.contains('my rating') || message.contains('my ratig') || 
        message.contains('profile rating') || message.contains('my review') ||
        message.contains('my score')) {
      return await getMyRating(user);
    }
    
    // Handle contact number queries (with typo tolerance)
    if (message.contains('my contact') || message.contains('my number') || 
        message.contains('my phone') || message.contains('my mobile') ||
        message.contains('contact number') || message.contains('phone number') ||
        message.contains('my numer') || message.contains('contact number')) {
      return await getMyContactNumber(user);
    }
    
    if (message.contains('request limit') || message.contains('quota')) {
      return await getRequestLimit(user);
    }
    
    if (message.contains('how many') || message.contains('total') || message.contains('statistics') || message.contains('stats')) {
      return await getStatistics(message);
    }
    
    if (message.contains('recent') || message.contains('latest')) {
      return await getRecentItems();
    }
    
    if (message.contains('electronics')) {
      return await getItemsByCategory('electronics');
    }
    
    return 'What data would you like to see? Try:\n'
        '• "My donations"\n'
        '• "My requests"\n'
        '• "How many items?"\n'
        '• "Recent items"\n'
        '• "Show electronics"';
  }
  
  Future<String> getMyDonations(User? user) async {
    if (user == null) return '🔒 Please log in to view your donations.';
    
    try {
      final items = await firestore
          .collection('items')
          .where('ownerId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();
      
      if (items.docs.isEmpty) {
        return '📦 **You haven\'t posted any items yet.**\n\n'
            'Ready to donate?\n'
            '1. Go to Profile tab\n'
            '2. Tap "Post a new donation"\n'
            '3. Fill in details\n'
            '4. Help someone in need! 😊';
      }
      
      String list = '';
      int available = 0;
      for (var doc in items.docs) {
        final data = doc.data();
        final title = data['title'] ?? 'Unknown';
        final isAvailable = data['available'] == true;
        final status = isAvailable ? '✅' : '🔴';
        if (isAvailable) available++;
        list += '• $title $status\n';
      }
      
      return '📦 **Your Recent Donations:**\n\n'
          '$list\n'
          '✅ Available: $available\n'
          '🔴 Not available: ${items.docs.length - available}\n\n'
          'View all in **Donor Dashboard**!';
    } catch (e) {
      return '❌ Error fetching your donations. Please try again.';
    }
  }
  
  Future<String> getMyRequests(User? user) async {
    if (user == null) return '🔒 Please log in to view your requests.';
    
    try {
      final requests = await firestore
          .collection('requests')
          .where('seekerId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();
      
      if (requests.docs.isEmpty) {
        return '🙋 **You haven\'t requested any items yet.**\n\n'
            'Start browsing:\n'
            '1. Go to Home or Search tab\n'
            '2. Find items you need\n'
            '3. Tap "Request" button\n'
            '4. Maximum 4 requests per month! 📊';
      }
      
      final pending = requests.docs.where((d) => d['status'] == 'pending').length;
      final approved = requests.docs.where((d) => d['status'] == 'approved').length;
      final rejected = requests.docs.where((d) => d['status'] == 'rejected').length;
      
      return '🙋 **Your Request Status:**\n\n'
          '🟡 Pending: $pending\n'
          '🟢 Approved: $approved\n'
          '🔴 Rejected: $rejected\n\n'
          'Total requests: ${requests.docs.length}\n\n'
          'Check **Seeker Dashboard** for details!\n\n'
          'Need help? Ask "how to request?"';
    } catch (e) {
      return '❌ Error fetching your requests. Please try again.';
    }
  }
  
  Future<String> getRequestLimit(User? user) async {
    if (user == null) return '🔒 Please log in to check your limit.';
    
    try {
      final userDoc = await firestore.collection('users').doc(user.uid).get();
      final data = userDoc.data() ?? {};
      final requests = (data['monthlyRequests'] as Map<String, dynamic>?) ?? {};
      
      final now = DateTime.now();
      final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';
      final used = (requests[monthKey] as int?) ?? 0;
      final remaining = 4 - used;
      
      String status;
      if (used < 4) {
        status = '✅ You can still request!';
      } else {
        status = '❌ Limit reached. Try next month.';
      }
      
      return '📊 **Monthly Request Limit:**\n\n'
          'Used: $used / 4 requests\n'
          'Remaining: $remaining\n\n'
          '$status\n\n'
          '💡 **Tip:** Requests reset on the 1st of each month!';
    } catch (e) {
      return '❌ Error checking limit. Please try again.';
    }
  }
  
  Future<String> getStatistics(String message) async {
    try {
      final items = await firestore.collection('items').get();
      final profiles = await firestore.collection('publicProfiles').get();
      final availableItems = items.docs.where((d) => d['available'] == true).length;
      
      return '📊 **ReuseHub Community Stats:**\n\n'
          '👥 Total Users: ${profiles.docs.length}\n'
          '📦 Total Items: ${items.docs.length}\n'
          '✅ Available Now: $availableItems\n'
          '🤝 Items Donated: ${items.docs.length - availableItems}\n\n'
          '🌟 **Join our growing community!**\n'
          'Together we reduce waste & help others! 🌍';
    } catch (e) {
      return '❌ Error fetching statistics. Please try again.';
    }
  }
  
  Future<String> getRecentItems() async {
    try {
      final items = await firestore
          .collection('items')
          .where('available', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();
      
      if (items.docs.isEmpty) {
        return '📭 **No items available right now.**\n\n'
            'Be the first to donate!\n'
            'Go to Profile → Post a new donation';
      }
      
      String list = '';
      for (var doc in items.docs) {
        final data = doc.data();
        final title = data['title'] ?? 'Unknown';
        final category = data['category'] ?? 'Other';
        list += '• $title ($category)\n';
      }
      
      return '🆕 **Recent Available Items:**\n\n'
          '$list\n'
          'Browse more on **Home** screen!\n\n'
          '💡 Tap items to see full details & request! 🙋';
    } catch (e) {
      return '❌ Error fetching items. Please try again.';
    }
  }
  
  Future<String> getItemsByCategory(String category) async {
    try {
      final items = await firestore
          .collection('items')
          .where('available', isEqualTo: true)
          .where('category', isEqualTo: category)
          .limit(5)
          .get();
      
      if (items.docs.isEmpty) {
        return '📭 **No $category items available right now.**\n\n'
            'Try:\n'
            '• Searching for other categories\n'
            '• Checking back later\n'
            '• Browse all items on Home screen';
      }
      
      String list = '';
      for (var doc in items.docs) {
        final data = doc.data();
        final title = data['title'] ?? 'Unknown';
        final condition = data['condition'] ?? 'Unknown';
        list += '• $title ($condition)\n';
      }
      
      return '📱 **Available $category:**\n\n'
          '$list\n'
          'Find these and more in **Search** tab!\n\n'
          'Tap to view details & request! 🙋';
    } catch (e) {
      return '❌ Error fetching items. Please try again.';
    }
  }
  
  String handleUnknown(String message) {
    return '🤔 **I\'m not sure about that.**\n\n'
        'Try asking:\n\n'
        '❓ "How to donate?"\n'
        '❓ "How to request items?"\n'
        '❓ "My donations"\n'
        '❓ "My rating"\n'
        '❓ "My contact number"\n'
        '❓ "How to contact another user?"\n'
        '❓ "How many items?"\n'
        '❓ "Technical support"\n\n'
        'Or tap the **quick action buttons** below! 👇\n\n'
        '💡 Tip: Try being more specific!';
  }
  
  // Log feedback for tracking chatbot performance (NOT for machine learning)
  // This helps developers see which responses users find helpful
  Future<void> logFeedback(String question, String response, bool helpful) async {
    try {
      await firestore.collection('chatbot_feedback').add({
        'question': question,
        'response': response,
        'helpful': helpful,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error logging feedback: $e');
    }
  }
  
  // Get user's contact number from their profile
  Future<String> getMyContactNumber(User? user) async {
    if (user == null) return '🔒 Please log in to view your contact number.';
    
    try {
      final userDoc = await firestore.collection('users').doc(user.uid).get();
      
      if (!userDoc.exists) {
        return '❌ **Profile not found.**\n\n'
            'Please update your profile first:\n'
            '1. Go to **Profile** tab\n'
            '2. Tap edit icon\n'
            '3. Add your mobile number\n'
            '4. Save changes';
      }
      
      final data = userDoc.data();
      final mobile = data?['mobile'] ?? '';
      final name = data?['name'] ?? 'User';
      final email = data?['email'] ?? user.email ?? '';
      
      if (mobile.isEmpty) {
        return '📱 **No contact number on file.**\n\n'
            'Add your mobile number:\n'
            '1. Go to **Profile** tab\n'
            '2. Tap edit icon (✏️)\n'
            '3. Enter your mobile number\n'
            '4. Tap "Save Changes"\n\n'
            '💡 This helps donors/seekers coordinate pickups!';
      }
      
      return '📱 **Your Contact Information:**\n\n'
          '**Name:** $name\n'
          '**Mobile:** $mobile\n'
          '**Email:** $email\n\n'
          '✏️ **Update Info:**\n'
          'Profile tab → Edit icon → Update details\n\n'
          '🔒 **Privacy:** Your number is private and only visible to you!';
    } catch (e) {
      return '❌ Error fetching contact info. Please try again.';
    }
  }
  
  // Get user's rating/reviews from their profile
  Future<String> getMyRating(User? user) async {
    if (user == null) return '🔒 Please log in to view your rating.';
    
    try {
      // Get all reviews for this user as a donor
      final reviews = await firestore
          .collection('reviews')
          .where('donorId', isEqualTo: user.uid)
          .get();
      
      if (reviews.docs.isEmpty) {
        return '⭐ **You don\'t have any ratings yet.**\n\n'
            'How to get ratings:\n'
            '1. Donate items to seekers\n'
            '2. Complete successful donations\n'
            '3. Seekers can review you\n\n'
            '💡 Build your reputation by donating! 🎁';
      }
      
      // Calculate average rating
      double totalRating = 0;
      for (var doc in reviews.docs) {
        final data = doc.data();
        totalRating += (data['rating'] ?? 0).toDouble();
      }
      
      final avgRating = totalRating / reviews.docs.length;
      final starDisplay = '⭐' * avgRating.round();
      
      // Count ratings by stars
      final fiveStar = reviews.docs.where((d) => d['rating'] == 5).length;
      final fourStar = reviews.docs.where((d) => d['rating'] == 4).length;
      final threeStar = reviews.docs.where((d) => d['rating'] == 3).length;
      final twoStar = reviews.docs.where((d) => d['rating'] == 2).length;
      final oneStar = reviews.docs.where((d) => d['rating'] == 1).length;
      
      return '⭐ **Your Donor Rating:**\n\n'
          '$starDisplay ${avgRating.toStringAsFixed(1)}/5.0\n'
          'Based on ${reviews.docs.length} review${reviews.docs.length > 1 ? "s" : ""}\n\n'
          '**Rating Breakdown:**\n'
          '⭐⭐⭐⭐⭐ $fiveStar\n'
          '⭐⭐⭐⭐ $fourStar\n'
          '⭐⭐⭐ $threeStar\n'
          '⭐⭐ $twoStar\n'
          '⭐ $oneStar\n\n'
          '💡 View all reviews on your public profile!\n\n'
          '🌟 Keep up the good work!';
    } catch (e) {
      return '❌ Error fetching your rating. Please try again.';
    }
  }
  
  // Clear conversation history
  void clearHistory() {
    conversationHistory.clear();
    lastTopic = null;
  }
}
