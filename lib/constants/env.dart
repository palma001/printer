import "package:flutter_dotenv/flutter_dotenv.dart";

class EnvVariables {
  static String? get apiUrl => dotenv.env["API_URL"] ?? "";
  static String? get pusherAppKey => dotenv.env["PUSHER_APP_KEY"] ?? "";
  static String? get pusherCluster => dotenv.env["PUSHER_CLUSTER"] ?? "";
  static String? get channel => dotenv.env["CHANNEL"] ?? "";
  static String? get eventName => dotenv.env["EVENT_NAME"] ?? "";
  static String? get receiptFontName => dotenv.env["RECEIPT_FONT_NAME"] ?? "";
  static String? get receiptFontSize => dotenv.env["RECEIPT_FONT_SIZE"] ?? "";
  static String get receiptTicketPaperSize =>
      dotenv.env["RECEIPT_TICKET_PAPER_SIZE"] ?? "";
  static String get receiptComandaPaperSize =>
      dotenv.env["RECEIPT_COMANDA_PAPER_SIZE"] ?? "";
}
