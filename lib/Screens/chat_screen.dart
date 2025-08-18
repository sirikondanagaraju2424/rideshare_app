// lib/screens/chat_screen.dart -- FINAL AND EXACTLY CORRECT CODE

import 'dart:async';
import 'package:amplify_flutter/amplify_flutter.dart';
// THIS IMPORT IS THE CRITICAL FIX that solves the errors.
import 'package:amplify_api/amplify_api.dart';
import 'package:flutter/material.dart';
import 'package:rideshare_app/models/ModelProvider.dart';
import 'package:rideshare_app/models/ride_model.dart';

// No manual Message class is needed.

class ChatScreen extends StatefulWidget {
  final Ride ride;
  const ChatScreen({super.key, required this.ride});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  List<Message> _messages = [];
  StreamSubscription? _subscription;
  bool _isLoading = true;
  String? _errorMessage;

  // --- Convenience Getters ---
  String get chatRoomID => widget.ride.rideId;
  String get currentUsername => 'Sita';
  String get currentUserId => 'sita-customer-456';

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _messageController.dispose();
    super.dispose();
  }

  // =======================================================================
  // ===                 BACKEND COMMUNICATION LOGIC                     ===
  // =======================================================================

  Future<void> _initializeChat() async {
    if (!Amplify.isConfigured) {
      if (mounted) {
        setState(() {
          _errorMessage = "Could not connect. Please restart.";
          _isLoading = false;
        });
      }
      return;
    }
    await _fetchMessages();
    _subscribeToNewMessages();
  }

  Future<void> _fetchMessages() async {
    try {
      final request = ModelQueries.list(
        Message.classType,
        where: Message.RIDEID.eq(chatRoomID),
      );
      final response = await Amplify.API.query(request: request).response;
      final messages = response.data?.items.whereType<Message>().toList();

      if (messages != null) {
        // Safely sort messages, handling cases where createdAt might be null
        messages.sort((a, b) => (a.createdAt ?? TemporalDateTime(DateTime(0)))
            .compareTo(b.createdAt ?? TemporalDateTime(DateTime(0))));
        if (mounted) {
          setState(() {
            _messages = messages;
          });
        }
      }
    } catch (e) {
      print('Error fetching messages: $e');
      if (mounted) setState(() => _errorMessage = "Could not load messages.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _subscribeToNewMessages() {
    final request = ModelSubscriptions.onCreate(Message.classType);
    final stream = Amplify.API.subscribe(
      request,
      onEstablished: () => print('Subscription established'),
    );

    _subscription = stream.listen((response) {
      final newMessage = response.data;
      if (mounted && newMessage != null && newMessage.rideId == chatRoomID) {
        setState(() {
          if (!_messages.any((msg) => msg.id == newMessage.id)) {
            _messages.add(newMessage);
          }
        });
      }
    }, onError: (error) {
      print('Error with message subscription: $error');
    });
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;

    try {
      final newMessage = Message(
        rideId: chatRoomID,
        messageText: messageText,
        senderId: currentUserId,
        senderName: currentUsername,
      );
      final request = ModelMutations.create(newMessage);
      await Amplify.API.mutate(request: request).response;
      _messageController.clear();
      FocusScope.of(context).unfocus();
    } catch (e) {
      print('Error sending message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: ${e.toString()}')),
        );
      }
    }
  }

  // =======================================================================
  // ===                         UI WIDGETS                            ===
  // =======================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chat for ride')),
      body: Column(
        children: [
          Expanded(child: _buildChatContent()),
          _buildMessageComposer(),
        ],
      ),
    );
  }

  Widget _buildChatContent() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_errorMessage != null) return Center(child: Text(_errorMessage!));
    if (_messages.isEmpty) return const Center(child: Text("Start the conversation!"));

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isSentByMe = message.senderName == currentUsername;
        return _buildMessageBubble(message, isSentByMe);
      },
    );
  }

  Widget _buildMessageBubble(Message message, bool isSentByMe) {
    final alignment =
        isSentByMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bubbleColor = isSentByMe ? Colors.blue : const Color(0xFFEAEAEA);
    final textColor = isSentByMe ? Colors.white : Colors.black;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          if (!isSentByMe)
            Padding(
              padding: const EdgeInsets.only(left: 8.0, bottom: 2.0),
              child: Text(
                message.senderName ?? 'Guest',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Text(
              message.messageText,
              style: TextStyle(color: textColor, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageComposer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: Colors.white,
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: "Type a message",
                  filled: true,
                  fillColor: const Color(0xFFF1F1F1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8.0),
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: _sendMessage,
              color: Colors.blue,
            ),
          ],
        ),
      ),
    );
  }
}