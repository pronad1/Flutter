import 'package:google_generative_ai/google_generative_ai.dart';
import 'enhanced_chatbot_service.dart';

class HybridChatbotService extends EnhancedChatbotService {
  GenerativeModel? _geminiModel;
  bool _isGeminiEnabled = false;
  
  // Initialize Gemini with your API key
  void initializeGemini(String apiKey) {
    try {
      _geminiModel = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey,
        systemInstruction: Content.text('''
You are ReuseHub AI Assistant, a helpful chatbot for the ReuseHub platform.

**About ReuseHub:**
ReuseHub is a donation and item reuse platform where:
- Donors post items they want to give away for free (unlimited posts)
- Seekers browse and request items they need (maximum 4 requests per month)
- Items are organized in 20+ categories: Electronics, Books, Furniture, Clothing, Sports, Toys, Tools, Kitchen, Art, Garden, Automotive, Baby, Pets, Health, Musical Instruments, Phone Accessories, Computer Parts, Camera, Educational, Office Supplies, and Other
- Items have 8 condition levels: Brand New, Like New, Excellent, Very Good, Good, Fair, Used, For Parts
- Users rate each other after exchanges (1-5 stars)
- Each item has a pickup address where seekers collect items
- Users manage donations via Donor Dashboard and requests via Seeker Dashboard

**Your Role:**
- Be helpful, friendly, and concise (maximum 150 words per response)
- Use relevant emojis to make responses engaging
- Focus on ReuseHub features and functionality
- If asked about unrelated topics, politely redirect to ReuseHub features
- Provide actionable step-by-step guidance when users need help
- Encourage community participation and sustainable reuse

**Key Features to Explain:**
1. **Donating:** Profile → Post a new donation → Fill details → Choose category/condition → Add photos & address → Post
2. **Requesting:** Browse Home/Search → Find item → Check details → Tap Request → Wait for approval
3. **Monthly Limit:** Seekers can request maximum 4 items per month (resets 1st of each month)
4. **Ratings:** Visit user profile → Scroll to "Leave a review" → Choose stars → Write review → Submit
5. **Dashboard:** Donors track their posts, seekers track their requests

**Response Style:**
- Start with an emoji related to the topic
- Use bullet points or numbered lists for clarity
- Include practical tips where relevant
- End with a helpful suggestion or next step
- Keep responses under 150 words unless absolutely necessary
        '''),
        generationConfig: GenerationConfig(
          temperature: 0.7,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 500,
        ),
      );
      _isGeminiEnabled = true;
      print('✅ Gemini AI initialized successfully');
    } catch (e) {
      print('❌ Gemini initialization failed: $e');
      _isGeminiEnabled = false;
    }
  }
  
  @override
  Future<String> getResponse(String userMessage) async {
    // First, try the rule-based system (fast & free)
    final intent = detectIntent(userMessage.toLowerCase());
    
    // If we have a clear intent, use rule-based response (80% of queries)
    if (intent != 'unknown') {
      return super.getResponse(userMessage);
    }
    
    // For unknown/complex queries, use Gemini AI (20% of queries)
    if (_isGeminiEnabled && _geminiModel != null) {
      try {
        return await _getGeminiResponse(userMessage);
      } catch (e) {
        print('⚠️ Gemini error: $e');
        // Fallback to rule-based if Gemini fails
        return super.getResponse(userMessage);
      }
    }
    
    // If Gemini is disabled, use rule-based
    return super.getResponse(userMessage);
  }
  
  Future<String> _getGeminiResponse(String userMessage) async {
    if (_geminiModel == null) {
      return super.getResponse(userMessage);
    }
    
    // Add delay to simulate processing
    await Future.delayed(const Duration(milliseconds: 1500));
    
    try {
      // Build context from conversation history if available
      String contextInfo = '';
      if (conversationHistory.isNotEmpty && conversationHistory.length >= 2) {
        final lastExchange = conversationHistory.last;
        contextInfo = '\n\nRecent context: User previously asked about "${lastExchange['user']}"';
      }
      
      final prompt = '''
User question: "$userMessage"$contextInfo

Provide a helpful answer about ReuseHub features. Keep response under 150 words.
Use emojis and be friendly. Focus only on ReuseHub functionality.
''';
      
      final chat = _geminiModel!.startChat();
      final response = await chat.sendMessage(Content.text(prompt));
      
      final aiResponse = response.text?.trim() ?? '';
      
      if (aiResponse.isEmpty) {
        return super.getResponse(userMessage);
      }
      
      return '🤖 **AI Assistant:**\n\n$aiResponse\n\n💡 Need more help? Just ask!';
      
    } catch (e) {
      print('❌ Gemini API error: $e');
      // Fallback to rule-based
      return super.getResponse(userMessage);
    }
  }
  
  // Check if Gemini is enabled
  bool get isAiEnabled => _isGeminiEnabled;
  
  // Disable Gemini (use only rule-based)
  void disableAi() {
    _isGeminiEnabled = false;
  }
  
  // Enable Gemini
  void enableAi() {
    if (_geminiModel != null) {
      _isGeminiEnabled = true;
    }
  }
}
