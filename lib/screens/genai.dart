/*import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GenAIScreen extends StatefulWidget {
  const GenAIScreen({super.key});

  @override
  State<GenAIScreen> createState() => _GenAIScreenState();
}

class _GenAIScreenState extends State<GenAIScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  // Color scheme matching your app
  final Color _primaryColor = const Color(0xFF3A2A8B); // Dark purple
  final Color _cardColor = const Color(0xFF1F1B3C); // Darker purple for cards
  final Color _accentColor = const Color(0xFF5A45D2); // Lighter purple for accents
  final Color _backgroundColor = const Color(0xFF121025); // Very dark purple background

  @override
  void initState() {
    super.initState();
    // Set system UI overlay style to match the dark theme
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: _backgroundColor,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
    
    // Add welcome message
    _messages.add(
      ChatMessage(
        text: "Hello! I'm your AI assistant for automotive queries. How can I help you today?",
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final userMessage = _messageController.text.trim();
    setState(() {
      _messages.add(
        ChatMessage(
          text: userMessage,
          isUser: true,
          timestamp: DateTime.now(),
        ),
      );
      _isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();

    // Simulate AI response delay
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _messages.add(
          ChatMessage(
            text: _generateAIResponse(userMessage),
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  String _generateAIResponse(String userMessage) {
    final String message = userMessage.toLowerCase();
    
    if (message.contains('engine') || message.contains('motor')) {
      return "For engine issues, I recommend checking the oil level, coolant, and air filter first. Common symptoms like unusual noises or poor performance often indicate specific problems. Would you like me to help diagnose based on specific symptoms?";
    } else if (message.contains('brake') || message.contains('braking')) {
      return "Brake issues should be addressed immediately for safety. Common signs include squealing sounds, vibrations, or spongy pedal feel. I recommend having your brake pads, rotors, and fluid checked by a qualified mechanic.";
    } else if (message.contains('tire') || message.contains('wheel')) {
      return "Tire maintenance is crucial for safety and fuel efficiency. Check tire pressure monthly, rotate tires every 6,000-8,000 miles, and watch for uneven wear patterns that might indicate alignment issues.";
    } else if (message.contains('oil') || message.contains('maintenance')) {
      return "Regular oil changes are essential for engine health. For most vehicles, change oil every 3,000-7,500 miles depending on oil type. Also consider regular maintenance like filter changes, fluid checks, and inspections.";
    } else if (message.contains('battery') || message.contains('electrical')) {
      return "Electrical issues can be tricky to diagnose. Common signs include dim lights, slow engine crank, or dashboard warning lights. Battery terminals should be clean and tight. Most car batteries last 3-5 years.";
    } else if (message.contains('hello') || message.contains('hi')) {
      return "Hello! I'm here to help with any automotive questions you have. Whether it's maintenance, troubleshooting, or general car care advice, feel free to ask!";
    } else {
      return "That's an interesting automotive question! Based on your query, I'd recommend consulting with a qualified mechanic for a proper diagnosis. In the meantime, ensure your vehicle is safe to drive and check your owner's manual for specific guidance.";
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showQuickActions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white54,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Questions',
                    style: TextStyle(
                      color: _accentColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildQuickActionTile(
                    'Engine making strange noises',
                    Icons.settings,
                  ),
                  _buildQuickActionTile(
                    'Brake system problems',
                    Icons.warning,
                  ),
                  _buildQuickActionTile(
                    'Battery not charging',
                    Icons.battery_alert,
                  ),
                  _buildQuickActionTile(
                    'Tire maintenance tips',
                    Icons.circle,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionTile(String text, IconData icon) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        _messageController.text = text;
        _sendMessage();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _primaryColor.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _accentColor.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: _accentColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white54,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Gen AI Assistant',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: _primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: _showQuickActions,
          ),
        ],
      ),
      body: Column(
        children: [
          // Header with AI info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_accentColor, _primaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.smart_toy,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Automotive Assistant',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Powered by advanced AI technology',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Chat messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),
          
          // Loading indicator
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _cardColor,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(_accentColor),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'AI is thinking...',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          
          // Message input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: Colors.white),
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      hintText: 'Ask me about your car...',
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: _backgroundColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_accentColor, _primaryColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: 
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: _accentColor,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(
                Icons.smart_toy,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isUser 
                    ? _accentColor 
                    : _cardColor,
                borderRadius: BorderRadius.circular(18).copyWith(
                  bottomLeft: message.isUser 
                      ? const Radius.circular(18) 
                      : const Radius.circular(4),
                  bottomRight: message.isUser 
                      ? const Radius.circular(4) 
                      : const Radius.circular(18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: _primaryColor,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}*/
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GenAIScreen extends StatefulWidget {
  const GenAIScreen({super.key});

  @override
  State<GenAIScreen> createState() => _GenAIScreenState();
}

class _GenAIScreenState extends State<GenAIScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  // Backend API configuration
  static const String _baseUrl = "https://fa8066ae5703.ngrok-free.app";
  static const String _chatEndpoint = "/chat";

  final Color _primaryColor = const Color(0xFF3A2A8B); // Dark purple
  final Color _cardColor = const Color(0xFF1F1B3C); // Darker purple for cards
  final Color _accentColor = const Color(
    0xFF5A45D2,
  ); // Lighter purple for accents
  final Color _backgroundColor = const Color(
    0xFF121025,
  ); // Very dark purple background

  @override
  void initState() {
    super.initState();
    // Set system UI overlay style to match the dark theme
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: _backgroundColor,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    // Add welcome message
    _messages.add(
      ChatMessage(
        text:
            "Hello! I'm your AI assistant for automotive queries. How can I help you today?",
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final userMessage = _messageController.text.trim();
    setState(() {
      _messages.add(
        ChatMessage(text: userMessage, isUser: true, timestamp: DateTime.now()),
      );
      _isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      // Get AI response from backend
      final aiResponse = await _getAIResponse(userMessage);

      if (mounted) {
        setState(() {
          _messages.add(
            ChatMessage(
              text: aiResponse,
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      // Fallback to local response if API fails
      if (mounted) {
        setState(() {
          _messages.add(
            ChatMessage(
              text:
                  "Sorry, I'm having trouble connecting to the server. Here's a general response: ${_generateLocalResponse(userMessage)}",
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  Future<String> _getAIResponse(String userMessage) async {
    try {
      // Prepare conversation history for the API
      List<Map<String, String>> conversationHistory = [];

      // Add previous messages (excluding the current user message we just added)
      for (int i = 0; i < _messages.length - 1; i++) {
        final message = _messages[i];
        conversationHistory.add({
          "role": message.isUser ? "user" : "assistant",
          "content": message.text,
        });
      }

      // Prepare request body
      final requestBody = {
        "message": userMessage,
        "conversation_history": conversationHistory,
      };

      // Make HTTP request
      final response = await http
          .post(
            Uri.parse("$_baseUrl$_chatEndpoint"),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(requestBody),
          )
          .timeout(
            const Duration(seconds: 30), // 30 second timeout
          );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return responseData['response'] ??
            'Sorry, I received an empty response.';
      } else {
        throw Exception('Server responded with status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error calling AI API: $e');
      rethrow; // Re-throw to be handled by the calling function
    }
  }

  // Fallback local response function (same as your original)
  String _generateLocalResponse(String userMessage) {
    final String message = userMessage.toLowerCase();

    if (message.contains('engine') || message.contains('motor')) {
      return "For engine issues, I recommend checking the oil level, coolant, and air filter first. Common symptoms like unusual noises or poor performance often indicate specific problems. Would you like me to help diagnose based on specific symptoms?";
    } else if (message.contains('brake') || message.contains('braking')) {
      return "Brake issues should be addressed immediately for safety. Common signs include squealing sounds, vibrations, or spongy pedal feel. I recommend having your brake pads, rotors, and fluid checked by a qualified mechanic.";
    } else if (message.contains('tire') || message.contains('wheel')) {
      return "Tire maintenance is crucial for safety and fuel efficiency. Check tire pressure monthly, rotate tires every 6,000-8,000 miles, and watch for uneven wear patterns that might indicate alignment issues.";
    } else if (message.contains('oil') || message.contains('maintenance')) {
      return "Regular oil changes are essential for engine health. For most vehicles, change oil every 3,000-7,500 miles depending on oil type. Also consider regular maintenance like filter changes, fluid checks, and inspections.";
    } else if (message.contains('battery') || message.contains('electrical')) {
      return "Electrical issues can be tricky to diagnose. Common signs include dim lights, slow engine crank, or dashboard warning lights. Battery terminals should be clean and tight. Most car batteries last 3-5 years.";
    } else if (message.contains('hello') || message.contains('hi')) {
      return "Hello! I'm here to help with any automotive questions you have. Whether it's maintenance, troubleshooting, or general car care advice, feel free to ask!";
    } else {
      return "That's an interesting automotive question! Based on your query, I'd recommend consulting with a qualified mechanic for a proper diagnosis. In the meantime, ensure your vehicle is safe to drive and check your owner's manual for specific guidance.";
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showQuickActions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white54,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick Questions',
                        style: TextStyle(
                          color: _accentColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildQuickActionTile(
                        'Engine making strange noises',
                        Icons.settings,
                      ),
                      _buildQuickActionTile(
                        'Brake system problems',
                        Icons.warning,
                      ),
                      _buildQuickActionTile(
                        'Battery not charging',
                        Icons.battery_alert,
                      ),
                      _buildQuickActionTile(
                        'Tire maintenance tips',
                        Icons.circle,
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildQuickActionTile(String text, IconData icon) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        _messageController.text = text;
        _sendMessage();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _primaryColor.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _accentColor.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: _accentColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Gen AI Assistant',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: _primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: _showQuickActions,
          ),
        ],
      ),
      body: Column(
        children: [
          // Header with AI info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_accentColor, _primaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.smart_toy,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Automotive Assistant',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Powered by advanced AI technology',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Chat messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),

          // Loading indicator
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _cardColor,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(_accentColor),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'AI is thinking...',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Message input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: Colors.white),
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      hintText: 'Ask me about your car...',
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: _backgroundColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_accentColor, _primaryColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: _accentColor,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(Icons.smart_toy, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isUser ? _accentColor : _cardColor,
                borderRadius: BorderRadius.circular(18).copyWith(
                  bottomLeft:
                      message.isUser
                          ? const Radius.circular(18)
                          : const Radius.circular(4),
                  bottomRight:
                      message.isUser
                          ? const Radius.circular(4)
                          : const Radius.circular(18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: _primaryColor,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 16),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}
