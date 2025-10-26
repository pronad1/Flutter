import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// AI Chatbot Service - Handles intelligent responses with real Firebase data
/// This can be extended to use real AI APIs (OpenAI, Gemini, etc.)
class ChatbotService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Simulated delay for realistic typing effect
  Future<String> getResponse(String userMessage) async {
    await Future.delayed(const Duration(milliseconds: 1500));

    final message = userMessage.toLowerCase().trim();

    // Statistics and count questions - ACCESS FIREBASE DATA
    if (_contains(message, ['how many', 'total', 'count', 'number of', 'statistics', 'stats'])) {
      return await _getStatistics(message);
    }

    // Recent items and posts
    if (_contains(message, ['recent', 'latest', 'new', 'last posted', 'show items'])) {
      return await _getRecentItems(message);
    }

    // Donation-related questions
    if (_contains(message, ['donate', 'donation', 'post item', 'add item', 'give'])) {
      return _getDonationHelp(message);
    }

    // Search-related questions
    if (_contains(message, ['search', 'find', 'look for', 'browse'])) {
      return _getSearchHelp(message);
    }

    // Request-related questions
    if (_contains(message, ['request', 'receive', 'get item', 'seeker'])) {
      return _getRequestHelp(message);
    }

    // Profile-related questions
    if (_contains(message, ['profile', 'account', 'bio', 'photo', 'edit profile'])) {
      return _getProfileHelp(message);
    }

    // Rating and review questions
    if (_contains(message, ['rating', 'review', 'star', 'feedback'])) {
      return _getRatingHelp(message);
    }

    // Email and contact questions
    if (_contains(message, ['email', 'contact', 'message', 'reach out'])) {
      return _getContactHelp(message);
    }

    // Pickup address questions
    if (_contains(message, ['address', 'pickup', 'location', 'where'])) {
      return _getAddressHelp(message);
    }

    // Chat questions
    if (_contains(message, ['chat', 'messaging', 'talk', 'conversation'])) {
      return _getChatHelp(message);
    }

    // Approval process
    if (_contains(message, ['approval', 'approve', 'pending', 'verify', 'admin'])) {
      return _getApprovalHelp(message);
    }

    // Role questions
    if (_contains(message, ['role', 'donor', 'seeker', 'switch'])) {
      return _getRoleHelp(message);
    }

    // Technical issues
    if (_contains(message, ['error', 'problem', 'issue', 'bug', 'not working', 'broken'])) {
      return _getTechnicalHelp(message);
    }

    // Greetings
    if (_contains(message, ['hi', 'hello', 'hey', 'good morning', 'good afternoon'])) {
      return '👋 Hello! I\'m here to help you with anything about the donation app. You can ask me about:\n\n'
          '• How to donate items\n'
          '• How to search and request items\n'
          '• Profile and account settings\n'
          '• Rating and reviews\n'
          '• Any technical issues\n\n'
          'What would you like to know?';
    }

    // Thanks
    if (_contains(message, ['thank', 'thanks', 'appreciate'])) {
      return '😊 You\'re welcome! Feel free to ask if you need any more help. Happy to assist!';
    }

    // Default response with suggestions
    return '🤔 I\'m not sure I understood that. Here are some things I can help with:\n\n'
        '• **Donating items** - How to post and manage donations\n'
        '• **Requesting items** - How to find and request items you need\n'
        '• **Profile setup** - Managing your account and visibility\n'
        '• **Ratings & Reviews** - Understanding the feedback system\n'
        '• **Technical support** - Solving any issues\n\n'
        'Try asking a specific question or click one of the quick actions above!';
  }

  bool _contains(String message, List<String> keywords) {
    return keywords.any((keyword) => message.contains(keyword));
  }

  String _getDonationHelp(String message) {
    if (_contains(message, ['how', 'post', 'add', 'create'])) {
      return '📦 **How to Donate an Item:**\n\n'
          '1. Go to your **Profile** tab\n'
          '2. Tap **"Post a new donation"**\n'
          '3. Fill in:\n'
          '   • Title (what is it?)\n'
          '   • Description (condition, details)\n'
          '   • Photo (optional but recommended)\n'
          '   • Category (Home, Electronics, Books, etc.)\n'
          '   • **Pickup Address** (where seekers can collect)\n'
          '4. Tap **"Post Item"**\n\n'
          '✅ Your item will appear on the home feed for seekers to request!';
    }

    if (_contains(message, ['edit', 'update', 'change'])) {
      return '✏️ **Edit Your Donation:**\n\n'
          '1. Go to **Donor Dashboard**\n'
          '2. Find "My donated items"\n'
          '3. Tap the edit icon on any item\n'
          '4. Update details and tap "Save"\n\n'
          'You can change the title, description, category, condition, and pickup address anytime!';
    }

    if (_contains(message, ['delete', 'remove'])) {
      return '🗑️ **Delete a Donation:**\n\n'
          '1. Go to **Donor Dashboard**\n'
          '2. Find the item you want to remove\n'
          '3. Tap the delete icon\n'
          '4. Confirm deletion\n\n'
          '⚠️ Note: You cannot delete items that have approved requests.';
    }

    return '📦 **Donation Features:**\n\n'
        '• Post items with photos and descriptions\n'
        '• Add pickup address for easy collection\n'
        '• Manage incoming requests\n'
        '• Edit or delete your items\n'
        '• Track your donation history\n\n'
        'What specific help do you need with donations?';
  }

  String _getSearchHelp(String message) {
    return '🔍 **How to Search for Items:**\n\n'
        '1. Tap the **Search** icon in bottom navigation\n'
        '2. Type what you\'re looking for (e.g., "laptop", "books")\n'
        '3. Browse results\n'
        '4. Tap any item to see details\n'
        '5. Tap donor\'s name to view their profile and ratings\n\n'
        '💡 **Tips:**\n'
        '• Use simple keywords\n'
        '• Check the pickup address before requesting\n'
        '• View donor profiles to see their ratings\n'
        '• Requested items show "Requested" status';
  }

  String _getRequestHelp(String message) {
    if (_contains(message, ['how', 'make', 'send'])) {
      return '🙋 **How to Request an Item:**\n\n'
          '1. Browse items on **Home** or **Search**\n'
          '2. Find an item you need\n'
          '3. Check the **pickup address**\n'
          '4. Tap **"Request"** button\n'
          '5. Wait for donor to approve\n\n'
          '📬 **What happens next:**\n'
          '• Donor receives your request\n'
          '• They can approve or reject it\n'
          '• You\'ll see status in "Incoming requests"\n'
          '• Once approved, arrange pickup via chat or email';
    }

    if (_contains(message, ['status', 'check', 'pending'])) {
      return '📊 **Check Request Status:**\n\n'
          '1. Go to **Seeker Dashboard**\n'
          '2. View "My requests" section\n'
          '3. Status indicators:\n'
          '   • 🟡 **Pending** - Waiting for donor\n'
          '   • 🟢 **Approved** - Ready for pickup!\n'
          '   • 🔴 **Rejected** - Try other items\n\n'
          'You can message approved donors or view their contact info!';
    }

    return '🙋 **Request Features:**\n\n'
        '• Request any available item\n'
        '• Track request status (pending/approved/rejected)\n'
        '• Contact donors after approval\n'
        '• View pickup addresses\n'
        '• Cancel requests if needed\n\n'
        'What do you need help with regarding requests?';
  }

  String _getProfileHelp(String message) {
    if (_contains(message, ['edit', 'update', 'change'])) {
      return '👤 **Edit Your Profile:**\n\n'
          '1. Go to **Profile** tab\n'
          '2. Tap the **Edit icon** (top right)\n'
          '3. Update:\n'
          '   • Profile photo\n'
          '   • Name\n'
          '   • Bio (tell people about yourself)\n'
          '   • Password (if needed)\n'
          '4. Tap **"Save Changes"**\n\n'
          '✨ Your changes will be visible to everyone who views your profile!';
    }

    if (_contains(message, ['bio', 'photo', 'visible', 'show'])) {
      return '🔒 **Profile Visibility:**\n\n'
          '**Public Profile** (visible to everyone):\n'
          '• Name\n'
          '• Profile photo\n'
          '• Bio\n'
          '• Ratings & reviews\n'
          '• Email contact button\n\n'
          '**Private Info** (only you see):\n'
          '• Email address\n'
          '• Phone number\n'
          '• Account settings\n\n'
          '💡 Keep your profile updated so people know who they\'re donating to/from!';
    }

    return '👤 **Profile Features:**\n\n'
        '• Public profile with photo and bio\n'
        '• Ratings and reviews from others\n'
        '• View your donation/request history\n'
        '• Email contact button\n'
        '• Role badges (Donor/Seeker)\n\n'
        'What would you like to do with your profile?';
  }

  String _getRatingHelp(String message) {
    if (_contains(message, ['how', 'give', 'leave'])) {
      return '⭐ **How to Rate Someone:**\n\n'
          '1. Complete a successful donation/request\n'
          '2. Visit the person\'s **public profile**\n'
          '3. Scroll to "Leave a review" section\n'
          '4. Choose 1-5 stars\n'
          '5. Write your experience (optional)\n'
          '6. Tap **"Submit Review"**\n\n'
          '💡 **Rating Tips:**\n'
          '• Be honest but respectful\n'
          '• Rate communication, condition, punctuality\n'
          '• Your review helps the community!';
    }

    if (_contains(message, ['see', 'view', 'check'])) {
      return '⭐ **View Ratings:**\n\n'
          '**Your Own Rating:**\n'
          '• Go to your **Profile** tab\n'
          '• See your average rating below your name\n\n'
          '**Others\' Ratings:**\n'
          '• Tap any donor/seeker name\n'
          '• Their profile shows rating stars\n'
          '• Scroll down to read reviews\n\n'
          '📊 Average ratings help build trust in the community!';
    }

    return '⭐ **Rating System:**\n\n'
        '• Rate users 1-5 stars ⭐⭐⭐⭐⭐\n'
        '• Write reviews about experiences\n'
        '• See average ratings on profiles\n'
        '• Build trust in the community\n\n'
        'Good ratings help users find reliable donors and seekers!';
  }

  String _getContactHelp(String message) {
    return '📧 **Contact Options:**\n\n'
        '**Email:**\n'
        '1. Visit someone\'s profile\n'
        '2. Tap **"Send Email"** button\n'
        '3. Choose your email app\n'
        '4. Send your message\n\n'
        '**Chat:**\n'
        '1. After request approval\n'
        '2. Tap "Chat" button\n'
        '3. Message directly in-app\n\n'
        '💡 **Best Practices:**\n'
        '• Be polite and clear\n'
        '• Arrange pickup times\n'
        '• Confirm addresses\n'
        '• Thank people after successful exchange';
  }

  String _getAddressHelp(String message) {
    return '📍 **Pickup Address Feature:**\n\n'
        '**For Donors:**\n'
        '• Add pickup address when posting items\n'
        '• Edit address anytime in item details\n'
        '• Shows with red pin icon 📍 on your items\n\n'
        '**For Seekers:**\n'
        '• See pickup address under each item description\n'
        '• Check if location works for you before requesting\n'
        '• Contact donor for exact details after approval\n\n'
        '💡 Clear addresses make pickup easier for everyone!';
  }

  String _getChatHelp(String message) {
    return '💬 **Chat/Messaging:**\n\n'
        '**Start a Chat:**\n'
        '1. Request must be approved first\n'
        '2. Go to **Chats** section\n'
        '3. Find your conversation\n'
        '4. Send messages\n\n'
        '**Features:**\n'
        '• Real-time messaging\n'
        '• Chat history saved\n'
        '• See online status\n'
        '• Arrange pickup details\n\n'
        'Use chat to coordinate pickups and ask questions!';
  }

  String _getApprovalHelp(String message) {
    if (_contains(message, ['how long', 'wait', 'time'])) {
      return '⏱️ **Approval Timeline:**\n\n'
          '• Depends on donor\'s availability\n'
          '• Most respond within 24-48 hours\n'
          '• Check your notifications regularly\n'
          '• Status shows in Seeker Dashboard\n\n'
          '💡 Tip: Request multiple items to increase chances!';
    }

    return '✅ **Approval Process:**\n\n'
        '**For Donors:**\n'
        '1. Receive requests in "Incoming requests"\n'
        '2. View seeker\'s profile and rating\n'
        '3. Tap "Approve" or "Reject"\n'
        '4. Contact approved seekers\n\n'
        '**For Seekers:**\n'
        '1. Send request on items you need\n'
        '2. Wait for donor decision\n'
        '3. Get notified of approval/rejection\n'
        '4. Arrange pickup if approved';
  }

  String _getRoleHelp(String message) {
    return '🎭 **Roles in the App:**\n\n'
        '**Donor:**\n'
        '• Post items to donate\n'
        '• Manage incoming requests\n'
        '• Approve/reject requests\n'
        '• View donation history\n\n'
        '**Seeker:**\n'
        '• Browse available items\n'
        '• Request items you need\n'
        '• Track request status\n'
        '• Contact donors\n\n'
        '**Admin:**\n'
        '• Approve new users\n'
        '• Monitor system activity\n'
        '• Manage reports\n\n'
        '💡 You can be both donor and seeker! Set your role in Profile → Edit Profile';
  }

  String _getTechnicalHelp(String message) {
    if (_contains(message, ['login', 'sign in', 'password'])) {
      return '🔐 **Login Issues:**\n\n'
          '**Forgot Password:**\n'
          '1. Tap "Forgot Password?" on login screen\n'
          '2. Enter your email\n'
          '3. Check inbox for reset link\n'
          '4. Click link and set new password\n\n'
          '**Can\'t Log In:**\n'
          '• Check email spelling\n'
          '• Verify password is correct\n'
          '• Ensure email is verified\n'
          '• Clear app cache and retry';
    }

    if (_contains(message, ['email', 'verify', 'verification'])) {
      return '📧 **Email Verification:**\n\n'
          '1. Check inbox for verification email\n'
          '2. Also check spam/junk folder\n'
          '3. Click the verification link\n'
          '4. Go back to app and tap "I Verified - Refresh"\n\n'
          '**Didn\'t Receive Email?**\n'
          '• Tap "Resend Email" button\n'
          '• Wait a few minutes\n'
          '• Check all email folders';
    }

    if (_contains(message, ['photo', 'image', 'upload'])) {
      return '📷 **Photo Upload Issues:**\n\n'
          '**If photos won\'t upload:**\n'
          '• Check internet connection\n'
          '• Ensure photo is under 5MB\n'
          '• Try different image format (JPG/PNG)\n'
          '• Grant camera/gallery permissions\n\n'
          '**Supported Formats:**\n'
          '• JPEG (.jpg, .jpeg)\n'
          '• PNG (.png)\n'
          '• Max size: 5MB';
    }

    return '🔧 **Technical Support:**\n\n'
        '**Common Issues:**\n'
        '• Login/password problems\n'
        '• Email verification\n'
        '• Photo uploads\n'
        '• App crashes\n'
        '• Slow loading\n\n'
        '**Quick Fixes:**\n'
        '1. Check internet connection\n'
        '2. Restart the app\n'
        '3. Clear cache\n'
        '4. Update to latest version\n\n'
        'Still having issues? Please describe the specific problem!';
  }

  // ==================== FIREBASE DATA ACCESS METHODS ====================
  
  /// Get real statistics from Firebase
  Future<String> _getStatistics(String message) async {
    try {
      // Count users using publicProfiles (public collection)
      if (_contains(message, ['user', 'member', 'people', 'account'])) {
        // Use publicProfiles instead of users (public read access)
        final profilesSnapshot = await _firestore.collection('publicProfiles').get();
        final totalProfiles = profilesSnapshot.docs.length;
        
        // Count unique donors and seekers from items collection
        final itemsSnapshot = await _firestore.collection('items').get();
        final uniqueDonors = itemsSnapshot.docs
            .map((doc) => doc.data()['ownerId'])
            .toSet()
            .length;
        
        return '👥 **User Statistics:**\n\n'
            '• **Total Profiles:** $totalProfiles users\n'
            '• **Active Donors:** $uniqueDonors donors\n'
            '• **Total Items Posted:** ${itemsSnapshot.docs.length}\n\n'
            '📊 The community is growing! Join us in sharing and caring!';
      }

      // Count items/donations
      if (_contains(message, ['item', 'donation', 'post', 'product'])) {
        final itemsSnapshot = await _firestore.collection('items').get();
        final totalItems = itemsSnapshot.docs.length;
        
        final availableItems = itemsSnapshot.docs.where((doc) => doc.data()['available'] == true).length;
        final unavailableItems = totalItems - availableItems;
        
        // Count by category
        final categories = <String, int>{};
        for (var doc in itemsSnapshot.docs) {
          final category = doc.data()['category']?.toString() ?? 'Other';
          categories[category] = (categories[category] ?? 0) + 1;
        }
        
        String categoryBreakdown = '';
        categories.forEach((category, count) {
          categoryBreakdown += '  • $category: $count items\n';
        });
        
        return '📦 **Item Statistics:**\n\n'
            '• **Total Items Posted:** $totalItems\n'
            '• **Available Items:** $availableItems\n'
            '• **Unavailable Items:** $unavailableItems\n\n'
            '**By Category:**\n$categoryBreakdown\n'
            '🎁 Thank you for sharing!';
      }

      // General statistics
      final profilesSnapshot = await _firestore.collection('publicProfiles').get();
      final itemsSnapshot = await _firestore.collection('items').get();
      
      final totalProfiles = profilesSnapshot.docs.length;
      final totalItems = itemsSnapshot.docs.length;
      final availableItems = itemsSnapshot.docs.where((doc) => doc.data()['available'] == true).length;
      
      return '📊 **ReuseHub Statistics:**\n\n'
          '👥 **Users:** $totalProfiles members\n'
          '📦 **Total Items:** $totalItems donations\n'
          '✅ **Available Now:** $availableItems items\n\n'
          '🌟 Join our growing community of givers and receivers!';
          
    } catch (e) {
      return '❌ Sorry, I couldn\'t fetch the statistics right now. Please try again later.\n\n'
          'Error: ${e.toString()}';
    }
  }

  /// Get recent items from Firebase
  Future<String> _getRecentItems(String message) async {
    try {
      final itemsSnapshot = await _firestore
          .collection('items')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();

      if (itemsSnapshot.docs.isEmpty) {
        return '📭 **No Items Yet**\n\n'
            'Be the first to donate! Post an item and help someone in need. 💚';
      }

      String itemsList = '';
      for (var doc in itemsSnapshot.docs) {
        final data = doc.data();
        final title = data['title']?.toString() ?? 'Unknown Item';
        final category = data['category']?.toString() ?? 'Other';
        final available = data['available'] == true ? '✅ Available' : '❌ Taken';
        
        // Format date
        String dateStr = 'Unknown date';
        if (data['createdAt'] != null) {
          try {
            final timestamp = data['createdAt'] as Timestamp;
            final date = timestamp.toDate();
            final now = DateTime.now();
            final difference = now.difference(date);
            
            if (difference.inDays == 0) {
              dateStr = 'Today';
            } else if (difference.inDays == 1) {
              dateStr = 'Yesterday';
            } else if (difference.inDays < 7) {
              dateStr = '${difference.inDays} days ago';
            } else {
              dateStr = '${date.day}/${date.month}/${date.year}';
            }
          } catch (e) {
            dateStr = 'Unknown date';
          }
        }
        
        itemsList += '\n📌 **$title**\n'
            '   Category: $category\n'
            '   Posted: $dateStr\n'
            '   Status: $available\n';
      }

      return '🆕 **Recent Items Posted:**\n$itemsList\n'
          '💡 Tap any item to view details and request it!';
          
    } catch (e) {
      return '❌ Sorry, I couldn\'t fetch recent items right now.\n\n'
          'Error: ${e.toString()}';
    }
  }
}
