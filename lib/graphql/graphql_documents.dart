// lib/graphql/graphql_documents.dart

class GraphQLDocuments {
  // This MUTATION matches your schema's `sendMessage` mutation.
  // It sends a new message to the backend.
  static const String sendMessage = '''
    mutation SendMessage(
      \$rideId: ID!,
      \$messageText: String!,
      \$senderId: String,
      \$senderName: String
    ) {
      sendMessage(
        rideId: \$rideId,
        messageText: \$messageText,
        senderId: \$senderId,
        senderName: \$senderName
      ) {
        messageId
        rideId
        timestamp
        messageText
        senderId
        senderName
      }
    }
  ''';

  // This QUERY matches your schema's `getMessages` query.
  // It fetches all messages for a specific rideId.
  static const String getMessages = '''
    query GetMessages(\$rideId: ID!) {
      getMessages(rideId: \$rideId) {
        messageId
        rideId
        timestamp
        messageText
        senderId
        senderName
      }
    }
  ''';

  // This SUBSCRIPTION matches your schema's `onNewMessage` subscription.
  // It listens for new messages sent to a specific rideId.
  static const String onNewMessage = '''
    subscription OnNewMessage(\$rideId: ID!) {
      onNewMessage(rideId: \$rideId) {
        messageId
        rideId
        timestamp
        messageText
        senderId
        senderName
      }
    }
  ''';
}