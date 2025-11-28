import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Enhanced AI Chatbot Service - Comprehensive ReuseHub Assistant
/// Provides intelligent responses about items, users, requests, and all app features
class ChatbotService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Simulated delay for realistic typing effect
  Future<String> getResponse(String userMessage) async {
    await Future.delayed(const Duration(milliseconds: 1500));

    final message = userMessage.toLowerCase().trim();
    
    // Get current user context for personalized responses
    final currentUser = _auth.currentUser;

    // === PERSONALIZED USER QUERIES ===
    if (_contains(message, ['my', 'i have', 'i posted', 'i donated', 'i requested'])) {
      return await _getPersonalizedInfo(message, currentUser);
    }

    // === REAL-TIME DATA QUERIES ===
    // Statistics and count questions - ACCESS FIREBASE DATA
    if (_contains(message, ['how many', 'total', 'count', 'number of', 'statistics', 'stats'])) {
      return await _getStatistics(message);
    }

    // Recent items and posts
    if (_contains(message, ['recent', 'latest', 'new', 'last posted', 'show items', 'show me items'])) {
      return await _getRecentItems(message);
    }
    
    // Available items queries
    if (_contains(message, ['available', 'what\'s available', 'what can i get', 'items available'])) {
      return await _getAvailableItems(message);
    }
    
    // Item by category
    if (_contains(message, ['electronics', 'computers', 'laptops', 'mobile', 'phones', 'furniture', 
                            'appliances', 'books', 'education', 'sports', 'fitness', 'clothing', 
                            'fashion', 'toys', 'games', 'kitchen', 'tools', 'hardware', 'garden'])) {
      return await _getItemsByCategory(message);
    }
    
    // Item by condition
    if (_contains(message, ['brand new', 'like new', 'excellent', 'good condition', 'fair', 'used'])) {
      return await _getItemsByCondition(message);
    }
    
    // Monthly request limit
    if (_contains(message, ['request limit', 'how many requests', 'monthly limit', 'request quota'])) {
      return await _getRequestLimitInfo(currentUser);
    }
    
    // User's requests status
    if (_contains(message, ['my requests', 'requests status', 'check requests', 'pending requests'])) {
      return await _getMyRequests(currentUser);
    }
    
    // User's donations/items
    if (_contains(message, ['my items', 'my donations', 'posted items', 'items i posted'])) {
      return await _getMyDonations(currentUser);
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
    if (_contains(message, ['hi', 'hello', 'hey', 'good morning', 'good afternoon', 'good evening'])) {
      final user = _auth.currentUser;
      final greeting = _getTimeBasedGreeting();
      final name = user?.displayName?.split(' ').first ?? 'there';
      
      return '$greeting $name! 👋\n\n'
          'I\'m your **ReuseHub AI Assistant**. I can help you with:\n\n'
          '**📦 Items & Donations**\n'
          '• "Show me recent items"\n'
          '• "What electronics are available?"\n'
          '• "How do I post an item?"\n'
          '• "My donations"\n\n'
          '**🙋 Requests**\n'
          '• "How to request an item?"\n'
          '• "Check my requests"\n'
          '• "What\'s my request limit?"\n\n'
          '**📊 Statistics**\n'
          '• "How many users?"\n'
          '• "Total items posted?"\n'
          '• "Available items?"\n\n'
          '**👤 Profile & Account**\n'
          '• "How to edit profile?"\n'
          '• "How does rating work?"\n'
          '• "Contact donor"\n\n'
          '**🔧 Technical Help**\n'
          '• "Login issues"\n'
          '• "Photo upload problems"\n'
          '• "Email verification"\n\n'
          'What would you like to know? Just ask naturally! 😊';
    }
    
    // Help and capabilities
    if (_contains(message, ['what can you do', 'help me', 'capabilities', 'features', 'commands'])) {
      return '🤖 **ReuseHub AI Assistant Capabilities**\n\n'
          'I can provide information about:\n\n'
          '**1️⃣ Real-Time Data (Live from Firebase)**\n'
          '✅ Recent items posted\n'
          '✅ Available items by category\n'
          '✅ Items by condition\n'
          '✅ Total users and statistics\n'
          '✅ Your personal donations\n'
          '✅ Your request status\n'
          '✅ Request limit usage\n\n'
          '**2️⃣ How-To Guides**\n'
          '📖 Post/edit/delete items\n'
          '📖 Search and request items\n'
          '📖 Manage requests (approve/reject)\n'
          '📖 Edit profile and settings\n'
          '📖 Rating system\n'
          '📖 Chat and messaging\n\n'
          '**3️⃣ Troubleshooting**\n'
          '🔧 Login problems\n'
          '🔧 Email verification\n'
          '🔧 Photo upload issues\n'
          '🔧 App errors\n\n'
          '**4️⃣ App Information**\n'
          '📱 Categories (20+ available)\n'
          '📱 Conditions (8 levels)\n'
          '📱 Features and policies\n'
          '📱 Best practices\n\n'
          '**💡 Try These Questions:**\n'
          '• "Show me available electronics"\n'
          '• "How many items are posted?"\n'
          '• "What\'s my request limit?"\n'
          '• "How to donate an item?"\n'
          '• "My pending requests"\n'
          '• "Show recent donations"\n\n'
          'Ask me anything! I\'m here to help! 😊';
    }

    // Thanks
    if (_contains(message, ['thank', 'thanks', 'appreciate'])) {
      return '😊 You\'re welcome! Feel free to ask if you need any more help. Happy to assist!\n\n'
          '💡 **Quick Tips:**\n'
          '• Ask about specific items: "Show me laptops"\n'
          '• Check your stats: "My donations" or "My requests"\n'
          '• Get help: "How to post an item?"\n'
          '• See data: "How many users?" or "Recent items"\n\n'
          'I\'m always here to help! 🎉';
    }

    // Default response with suggestions
    return '🤔 I\'m not quite sure what you\'re asking, but I\'m here to help!\n\n'
        '**💡 Try asking about:**\n\n'
        '**📦 Items:**\n'
        '• "Show me recent items"\n'
        '• "What electronics are available?"\n'
        '• "Items in good condition"\n'
        '• "Brand new items"\n\n'
        '**🙋 Requests:**\n'
        '• "How to request an item?"\n'
        '• "Check my requests"\n'
        '• "What\'s my request limit?"\n'
        '• "My pending requests"\n\n'
        '**📊 Statistics:**\n'
        '• "How many items?"\n'
        '• "Total users?"\n'
        '• "Available items?"\n\n'
        '**👤 Account:**\n'
        '• "How to edit profile?"\n'
        '• "My donations"\n'
        '• "How does rating work?"\n\n'
        '**🔧 Help:**\n'
        '• "How to donate?"\n'
        '• "How to search?"\n'
        '• "Technical issues"\n\n'
        'Or tap the quick action buttons above! 🎯';
  }

  bool _contains(String message, List<String> keywords) {
    return keywords.any((keyword) => message.contains(keyword));
  }
  
  /// Get time-based greeting
  String _getTimeBasedGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    if (hour < 21) return 'Good evening';
    return 'Hello';
  }

  String _getDonationHelp(String message) {
    if (_contains(message, ['how', 'post', 'add', 'create'])) {
      return '📦 **How to Donate an Item:**\n\n'
          '1. Go to your **Profile** tab\n'
          '2. Tap **"Post a new donation"** or the + button\n'
          '3. Fill in the details:\n'
          '   • **Title** - What is it? (e.g., "Samsung Galaxy S10")\n'
          '   • **Description** - Condition, features, details\n'
          '   • **Photo** - Add clear photos (recommended)\n'
          '   • **Category** - Choose from 20+ categories:\n'
          '     - Electronics, Computers, Mobile Phones\n'
          '     - Home & Furniture, Appliances\n'
          '     - Books & Education, Sports & Fitness\n'
          '     - Clothing & Fashion, Toys & Games\n'
          '     - Kitchen, Tools, Garden, Baby & Kids\n'
          '     - Health & Beauty, Automotive, Pet Supplies\n'
          '     - Office Supplies, Art & Crafts, Musical Instruments\n'
          '   • **Condition** - Brand New, Like New, Excellent, Good, Fair, Used, For Parts\n'
          '   • **Pickup Address** - Where to collect (required)\n'
          '   • **Price** (optional) - If selling instead of donating\n'
          '4. Tap **"Post Item"**\n\n'
          '✅ Your item will appear on the home feed instantly!\n\n'
          '💡 **Pro Tips:**\n'
          '• Add multiple photos for better visibility\n'
          '• Be honest about condition\n'
          '• Provide clear pickup instructions\n'
          '• Brand new items with prices get "Special Deal" badge!';
    }

    if (_contains(message, ['edit', 'update', 'change'])) {
      return '✏️ **Edit Your Donation:**\n\n'
          '1. Go to **Donor Dashboard** (Profile → My Donations)\n'
          '2. Find "My donated items" section\n'
          '3. Tap the **edit icon** (pencil) on any item\n'
          '4. Update any details:\n'
          '   • Title, description, photo\n'
          '   • Category, condition\n'
          '   • Pickup address\n'
          '   • Price (if selling)\n'
          '   • Availability status\n'
          '5. Tap **"Save Changes"**\n\n'
          '✅ Changes are reflected immediately!\n\n'
          '⚠️ **Note:** Items with approved requests cannot be made available again until the request is completed.';
    }

    if (_contains(message, ['delete', 'remove'])) {
      return '🗑️ **Delete a Donation:**\n\n'
          '1. Go to **Donor Dashboard**\n'
          '2. Find the item you want to remove\n'
          '3. Tap the **delete icon** (trash)\n'
          '4. Confirm deletion\n\n'
          '⚠️ **Important Restrictions:**\n'
          '• Cannot delete items with pending requests (reject them first)\n'
          '• Cannot delete items with approved requests\n'
          '• Deletion is permanent and cannot be undone\n\n'
          '💡 **Alternative:** Mark item as unavailable instead of deleting.';
    }
    
    if (_contains(message, ['price', 'sell', 'selling'])) {
      return '💰 **Selling Items:**\n\n'
          'ReuseHub supports both **donations** and **selling** items!\n\n'
          '**To Sell an Item:**\n'
          '1. When posting, enable "Selling" toggle\n'
          '2. Enter your price\n'
          '3. Choose condition\n\n'
          '**Special Deals:**\n'
          '• Brand new items with prices get a special badge\n'
          '• Appears in "Special Deals" section\n'
          '• Attracts more attention!\n\n'
          '**Pricing Tips:**\n'
          '• Research similar items\n'
          '• Consider condition\n'
          '• Be competitive\n'
          '• Clearly state "firm" or "negotiable"';
    }

    return '📦 **Donation Features:**\n\n'
        '**What You Can Do:**\n'
        '• Post unlimited items (donations or selling)\n'
        '• Add photos and detailed descriptions\n'
        '• Choose from 20+ categories\n'
        '• Set condition (8 levels from Brand New to For Parts)\n'
        '• Add pickup address for easy collection\n'
        '• Manage incoming requests (approve/reject)\n'
        '• Edit or delete your items anytime\n'
        '• Track your donation history\n'
        '• Get ratings from seekers\n\n'
        '**Categories Available:**\n'
        'Electronics, Computers, Phones, Furniture, Appliances, Books, Sports, Clothing, Toys, Kitchen, Tools, Garden, Baby Items, Health & Beauty, Automotive, Pet Supplies, Office, Arts & Crafts, Music, and more!\n\n'
        'What specific help do you need with donations?';
  }

  String _getSearchHelp(String message) {
    return '🔍 **How to Search for Items:**\n\n'
        '**Method 1: Search Tab**\n'
        '1. Tap **Search** icon in bottom navigation\n'
        '2. Type keywords (e.g., "laptop", "books", "chair")\n'
        '3. Browse search results\n'
        '4. Tap any item for full details\n\n'
        '**Method 2: Home Screen Filters**\n'
        '1. Go to **Home** tab\n'
        '2. Use filter buttons:\n'
        '   • **Category** - Filter by 20+ categories\n'
        '   • **Condition** - Brand New, Like New, Excellent, Good, Fair, Used, For Parts\n'
        '   • **Location** - Search by pickup location\n'
        '3. Combine filters for precise results\n'
        '4. Clear filters with the X button\n\n'
        '**Smart Features:**\n'
        '• Real-time search results\n'
        '• Filter by multiple criteria\n'
        '• See donor profiles and ratings\n'
        '• View pickup addresses before requesting\n'
        '• "Requested" badge shows items you already requested\n'
        '• "Special Deal" badge for brand new selling items\n\n'
        '💡 **Search Tips:**\n'
        '• Use simple, specific keywords\n'
        '• Try different variations (e.g., "phone" vs "mobile")\n'
        '• Check category filters for better results\n'
        '• Filter by condition to find quality items\n'
        '• Look at donor ratings before requesting\n'
        '• Check pickup address location\n\n'
        '**Popular Searches:**\n'
        '• Electronics: "laptop", "phone", "tablet", "headphones"\n'
        '• Furniture: "chair", "table", "sofa", "desk"\n'
        '• Books: "textbook", "novel", "study material"\n'
        '• Clothing: "jacket", "shoes", "dress"';
  }

  String _getRequestHelp(String message) {
    if (_contains(message, ['how', 'make', 'send'])) {
      return '🙋 **How to Request an Item:**\n\n'
          '1. Browse items on **Home** or **Search**\n'
          '2. Find an item you need\n'
          '3. Check these details first:\n'
          '   • ✅ Item is available (not already requested)\n'
          '   • 📍 Pickup address works for you\n'
          '   • ⭐ Donor has good ratings\n'
          '   • 📸 Photos match description\n'
          '4. Tap **"Request"** button\n'
          '5. Confirm your request\n\n'
          '📬 **What Happens Next:**\n'
          '• ✉️ Donor receives notification\n'
          '• ⏱️ They review your profile and request\n'
          '• ✅ They approve or ❌ reject your request\n'
          '• 📊 You see status in "My Requests"\n'
          '• 💬 If approved, you can chat with donor\n'
          '• 📧 Contact via email if needed\n'
          '• 🤝 Arrange pickup time and location\n\n'
          '⚠️ **Request Limit:**\n'
          '• Maximum 4 requests per month\n'
          '• Counter resets on 1st of each month\n'
          '• Choose wisely!\n'
          '• Check "My Requests" to see remaining quota\n\n'
          '💡 **Best Practices:**\n'
          '• Complete your profile before requesting\n'
          '• Have a good profile photo\n'
          '• Respond quickly to approved requests\n'
          '• Be polite in communications\n'
          '• Rate donors after successful pickup';
    }

    if (_contains(message, ['status', 'check', 'pending'])) {
      return '📊 **Check Request Status:**\n\n'
          '**Where to Check:**\n'
          '1. Go to **Seeker Dashboard** (Profile tab)\n'
          '2. View "My requests" section\n'
          '3. See all your requests with status\n\n'
          '**Status Meanings:**\n'
          '🟡 **Pending** - Waiting for donor decision\n'
          '   • Donor hasn\'t responded yet\n'
          '   • Usually takes 24-48 hours\n'
          '   • Be patient!\n\n'
          '🟢 **Approved** - Congratulations!\n'
          '   • Donor accepted your request\n'
          '   • Item is reserved for you\n'
          '   • Contact donor to arrange pickup\n'
          '   • Use chat or email button\n'
          '   • Confirm pickup address and time\n\n'
          '🔴 **Rejected** - Not this time\n'
          '   • Donor chose another requester\n'
          '   • Item no longer available\n'
          '   • Try requesting other similar items\n'
          '   • Don\'t be discouraged!\n\n'
          '⚪ **Completed** - Mission accomplished!\n'
          '   • You picked up the item\n'
          '   • Please rate the donor\n'
          '   • Share your experience\n\n'
          '**Action Buttons:**\n'
          '• 💬 **Chat** - Message donor (if approved)\n'
          '• 📧 **Email** - Send email to donor\n'
          '• 👤 **Profile** - View donor\'s profile\n'
          '• ❌ **Cancel** - Cancel your request (if still pending)\n\n'
          '💡 You can message approved donors to coordinate pickup!';
    }
    
    if (_contains(message, ['limit', 'how many', 'monthly'])) {
      return '📊 **Monthly Request Limit:**\n\n'
          '**Current System:**\n'
          '• Maximum: **4 requests per month**\n'
          '• Resets: **1st of each month**\n'
          '• Applies to: **All users equally**\n\n'
          '**How It Works:**\n'
          '• Each request counts immediately\n'
          '• Even if rejected, it still counts\n'
          '• Cancelled requests also count\n'
          '• Approved requests count\n\n'
          '**Check Your Usage:**\n'
          '1. Go to Seeker Dashboard\n'
          '2. See "X/4 requests used this month"\n'
          '3. Or ask me: "What\'s my request limit?"\n\n'
          '**Tips to Use Wisely:**\n'
          '• Only request items you really need\n'
          '• Check donor ratings first\n'
          '• Verify pickup location before requesting\n'
          '• Read item description carefully\n'
          '• Don\'t spam multiple similar items\n\n'
          '💡 Plan your requests carefully!';
    }

    return '🙋 **Request System Overview:**\n\n'
        '**Key Features:**\n'
        '• Request any available item\n'
        '• Track status: Pending/Approved/Rejected/Completed\n'
        '• Monthly limit: 4 requests per month\n'
        '• Contact donors after approval\n'
        '• View pickup addresses\n'
        '• Cancel pending requests\n'
        '• Rate donors after pickup\n\n'
        '**Request Workflow:**\n'
        '1️⃣ Browse items → Find what you need\n'
        '2️⃣ Request → Send request to donor\n'
        '3️⃣ Wait → Donor reviews (24-48h)\n'
        '4️⃣ Approved → Arrange pickup\n'
        '5️⃣ Pickup → Get the item\n'
        '6️⃣ Rate → Give feedback\n\n'
        '**Important Rules:**\n'
        '• ⚠️ 4 requests max per month\n'
        '• ⚠️ One request per item per user\n'
        '• ⚠️ Cannot request your own items\n'
        '• ⚠️ Must complete profile first\n'
        '• ⚠️ Email must be verified\n\n'
        'What specific help do you need with requests?';
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
  
  // ==================== NEW ENHANCED METHODS ====================
  
  /// Get personalized information based on current user
  Future<String> _getPersonalizedInfo(String message, User? user) async {
    if (user == null) {
      return '🔒 **Please Log In**\n\n'
          'To view your personal information, donations, and requests, please log in to your account.';
    }
    
    try {
      if (_contains(message, ['my items', 'my donations', 'posted', 'donated'])) {
        return await _getMyDonations(user);
      }
      
      if (_contains(message, ['my requests', 'requested', 'i requested'])) {
        return await _getMyRequests(user);
      }
      
      if (_contains(message, ['my profile', 'my account', 'my info'])) {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        final userData = userDoc.data();
        final name = userData?['name'] ?? 'User';
        final role = userData?['role'] ?? 'Not set';
        final email = user.email ?? 'Not set';
        
        return '👤 **Your Profile**\n\n'
            '**Name:** $name\n'
            '**Email:** $email\n'
            '**Role:** $role\n\n'
            'Tap Profile → Edit to update your information!';
      }
      
      return await _getMyDonations(user);
    } catch (e) {
      return '❌ Could not fetch your information. Please try again.';
    }
  }
  
  /// Get user's donated items
  Future<String> _getMyDonations(User? user) async {
    if (user == null) {
      return '🔒 Please log in to view your donations.';
    }
    
    try {
      final itemsSnapshot = await _firestore
          .collection('items')
          .where('ownerId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();
      
      if (itemsSnapshot.docs.isEmpty) {
        return '📦 **No Donations Yet**\n\n'
            'You haven\'t posted any items yet. Tap "Post Item" to donate something!';
      }
      
      final totalItems = itemsSnapshot.docs.length;
      final availableItems = itemsSnapshot.docs.where((doc) => doc.data()['available'] == true).length;
      
      String itemsList = '';
      for (var doc in itemsSnapshot.docs.take(5)) {
        final data = doc.data();
        final title = data['title'] ?? 'Unknown';
        final available = data['available'] == true ? '✅ Available' : '🔴 Requested';
        itemsList += '\n• **$title** - $available';
      }
      
      return '📦 **Your Donations**\n\n'
          'Total items posted: $totalItems\n'
          'Available: $availableItems\n'
          '$itemsList\n\n'
          'View all in Donor Dashboard!';
    } catch (e) {
      return '❌ Could not fetch your donations: ${e.toString()}';
    }
  }
  
  /// Get user's requests
  Future<String> _getMyRequests(User? user) async {
    if (user == null) {
      return '🔒 Please log in to view your requests.';
    }
    
    try {
      final requestsSnapshot = await _firestore
          .collection('requests')
          .where('seekerId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();
      
      if (requestsSnapshot.docs.isEmpty) {
        return '🙋 **No Requests Yet**\n\n'
            'You haven\'t requested any items yet. Browse available items and request what you need!';
      }
      
      final pending = requestsSnapshot.docs.where((doc) => doc.data()['status'] == 'pending').length;
      final approved = requestsSnapshot.docs.where((doc) => doc.data()['status'] == 'approved').length;
      final rejected = requestsSnapshot.docs.where((doc) => doc.data()['status'] == 'rejected').length;
      
      return '🙋 **Your Requests**\n\n'
          '🟡 Pending: $pending\n'
          '🟢 Approved: $approved\n'
          '🔴 Rejected: $rejected\n\n'
          'View details in Seeker Dashboard!';
    } catch (e) {
      return '❌ Could not fetch your requests: ${e.toString()}';
    }
  }
  
  /// Get request limit information
  Future<String> _getRequestLimitInfo(User? user) async {
    if (user == null) {
      return '🔒 Please log in to check your request limit.';
    }
    
    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};
      final monthlyRequests = (userData['monthlyRequests'] as Map<String, dynamic>?) ?? {};
      
      final now = DateTime.now();
      final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';
      final currentCount = (monthlyRequests[monthKey] as int?) ?? 0;
      const maxRequests = 4;
      
      final remaining = maxRequests - currentCount;
      
      return '📊 **Monthly Request Limit**\n\n'
          '**Used:** $currentCount / $maxRequests requests\n'
          '**Remaining:** $remaining requests\n\n'
          '${remaining > 0 ? '✅ You can still request $remaining items this month!' : '❌ Monthly limit reached. Try again next month.'}\n\n'
          '💡 The limit resets on the 1st of each month.';
    } catch (e) {
      return '❌ Could not fetch request limit: ${e.toString()}';
    }
  }
  
  /// Get available items
  Future<String> _getAvailableItems(String message) async {
    try {
      final itemsSnapshot = await _firestore
          .collection('items')
          .where('available', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();
      
      if (itemsSnapshot.docs.isEmpty) {
        return '📭 **No Available Items**\n\n'
            'There are no items available right now. Check back later!';
      }
      
      String itemsList = '';
      for (var doc in itemsSnapshot.docs.take(5)) {
        final data = doc.data();
        final title = data['title'] ?? 'Unknown';
        final category = data['category'] ?? 'Other';
        final condition = data['condition'] ?? 'Unknown';
        itemsList += '\n• **$title**\n  Category: $category | Condition: $condition';
      }
      
      return '✅ **Available Items (${itemsSnapshot.docs.length} total)**\n'
          '$itemsList\n\n'
          'Browse more on the Home screen!';
    } catch (e) {
      return '❌ Could not fetch available items: ${e.toString()}';
    }
  }
  
  /// Get items by category
  Future<String> _getItemsByCategory(String message) async {
    // Detect category from message
    String? category;
    final categoryMap = {
      'electronics': 'Electronics',
      'computers': 'Computers & Laptops',
      'laptop': 'Computers & Laptops',
      'mobile': 'Mobile Phones',
      'phone': 'Mobile Phones',
      'furniture': 'Home & Furniture',
      'home': 'Home & Furniture',
      'appliances': 'Appliances',
      'books': 'Books & Education',
      'education': 'Books & Education',
      'sports': 'Sports & Fitness',
      'fitness': 'Sports & Fitness',
      'clothing': 'Clothing & Fashion',
      'fashion': 'Clothing & Fashion',
      'toys': 'Toys & Games',
      'games': 'Toys & Games',
      'kitchen': 'Kitchen & Dining',
      'tools': 'Tools & Hardware',
      'hardware': 'Tools & Hardware',
      'garden': 'Garden & Outdoor',
    };
    
    for (var entry in categoryMap.entries) {
      if (message.contains(entry.key)) {
        category = entry.value;
        break;
      }
    }
    
    if (category == null) {
      return '🔍 **Search by Category**\n\n'
          'Available categories:\n'
          '• Electronics\n• Computers & Laptops\n• Mobile Phones\n'
          '• Home & Furniture\n• Appliances\n• Books & Education\n'
          '• Sports & Fitness\n• Clothing & Fashion\n• Toys & Games\n'
          '• Kitchen & Dining\n• Tools & Hardware\n• Garden & Outdoor\n\n'
          'Try asking: "Show me electronics" or "Do you have any books?"';
    }
    
    try {
      final itemsSnapshot = await _firestore
          .collection('items')
          .where('category', isEqualTo: category)
          .where('available', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();
      
      if (itemsSnapshot.docs.isEmpty) {
        return '📭 **No $category Items**\n\n'
            'Sorry, there are no available items in this category right now. Try other categories!';
      }
      
      String itemsList = '';
      for (var doc in itemsSnapshot.docs) {
        final data = doc.data();
        final title = data['title'] ?? 'Unknown';
        final condition = data['condition'] ?? 'Unknown';
        itemsList += '\n• **$title** - $condition';
      }
      
      return '📦 **$category (${itemsSnapshot.docs.length} available)**\n'
          '$itemsList\n\n'
          'Browse all items in the Search tab!';
    } catch (e) {
      return '❌ Could not fetch items: ${e.toString()}';
    }
  }
  
  /// Get items by condition
  Future<String> _getItemsByCondition(String message) async {
    String? condition;
    if (message.contains('brand new')) condition = 'Brand New';
    else if (message.contains('like new')) condition = 'Like New';
    else if (message.contains('excellent')) condition = 'Excellent';
    else if (message.contains('good')) condition = 'Good';
    else if (message.contains('fair')) condition = 'Fair';
    else if (message.contains('used')) condition = 'Used';
    
    if (condition == null) {
      return '🌟 **Search by Condition**\n\n'
          'Available conditions:\n'
          '• Brand New\n• Like New\n• Excellent\n• Good\n• Fair\n• Used\n\n'
          'Try asking: "Show me brand new items" or "What\'s in excellent condition?"';
    }
    
    try {
      final itemsSnapshot = await _firestore
          .collection('items')
          .where('condition', isEqualTo: condition)
          .where('available', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();
      
      if (itemsSnapshot.docs.isEmpty) {
        return '📭 **No $condition Items**\n\n'
            'Sorry, there are no available items in $condition condition right now.';
      }
      
      String itemsList = '';
      for (var doc in itemsSnapshot.docs) {
        final data = doc.data();
        final title = data['title'] ?? 'Unknown';
        final category = data['category'] ?? 'Other';
        itemsList += '\n• **$title** ($category)';
      }
      
      return '🌟 **$condition Items (${itemsSnapshot.docs.length} available)**\n'
          '$itemsList\n\n'
          'Browse all items on the Home screen!';
    } catch (e) {
      return '❌ Could not fetch items: ${e.toString()}';
    }
  }
}