part of 'mentor_bloc.dart';

abstract class PersonalEvent extends Equatable {
  @override
  bool? get stringify => true;

  @override
  List<Object?> get props => [];
}

class FetchPersonalEvents extends PersonalEvent {}

class UpdateToken extends PersonalEvent {
  final String? token;

  UpdateToken(this.token);

  @override
  List<Object?> get props => [token];
}

class FetchChatHistory extends PersonalEvent {
  final String? userId;
  final String? firstName;

  FetchChatHistory(this.userId, {this.firstName});

  @override
  List<Object?> get props => [userId];
}

class FlushPersonal extends PersonalEvent {}

class FetchCheatSheet extends PersonalEvent {}

class Initialise extends PersonalEvent {}

class UpdateScrollPosition extends PersonalEvent {
  final ScrollPosition position;

  UpdateScrollPosition(this.position);
}

class UpdateIsScrolling extends PersonalEvent {
  final bool isScrolling;

  UpdateIsScrolling(this.isScrolling);
}

class SendMessage extends PersonalEvent {
  final String message;
  final bool? hidden;
  final String? source;
  final int? sourceId;

  SendMessage(this.message, {this.hidden, this.source, this.sourceId});
}

class UpdateAnimatedStatus extends PersonalEvent {
  final String uniqueKey;
  final bool status;

  UpdateAnimatedStatus(this.uniqueKey, this.status);
}

class UpdateComponentState extends PersonalEvent {
  final String uniqueKey;
  final Map<String, dynamic> newValue;

  UpdateComponentState(this.uniqueKey, this.newValue);
}

class FetchInstrument extends PersonalEvent {
  final String ticker;

  FetchInstrument(this.ticker);
}

class DeleteMessage extends PersonalEvent {
  final MentorChat chat;

  DeleteMessage(this.chat);
}

class DeleteResponseOption extends PersonalEvent {
  final ResponseOption option;

  DeleteResponseOption(this.option);
}

class UpdateMentorFormState extends PersonalEvent {
  final MentorFormState state;
  final String uniqueKey;

  UpdateMentorFormState({required this.state, required this.uniqueKey});
}

class UpdatePersonalState extends PersonalEvent {
  final PersonalState state;

  UpdatePersonalState(this.state);
}

class UpdateScrollOffset extends PersonalEvent {
  final double? offset;

  UpdateScrollOffset(this.offset);
}

class QueueMessage extends PersonalEvent {
  final String message;

  QueueMessage(this.message);
}

class ClearQueue extends PersonalEvent {}

class SocketInsights extends PersonalEvent {}

class SaveMockPortfolio extends PersonalEvent {
  final String name;
  final double value;
  final List<Map<String, dynamic>> tickers;
  final String uniqueKey;
  final Function navigator;

  SaveMockPortfolio(
      {required this.name,
      required this.tickers,
      required this.value,
      required this.uniqueKey,
      required this.navigator});
}

class ClearSavePortFolioErrorMessage extends PersonalEvent {}
