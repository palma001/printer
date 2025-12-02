enum ChannelEventsType {
  GET_CURRENT_STATUS("GET_CURRENT_STATUS"),
  PRINTING("printing"),
  ERROR("error"),
  CONNECTED("connected"),
  DISCONNECTED("disconnected"),
  SENDING_PRINTERS("sending_printers"),
  RECEIVING("receiving"),
  CONNECTING("connecting");

  final String value;
  const ChannelEventsType(this.value);
}
