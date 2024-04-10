//Imports removed due to security reasons.

part 'mentor_event.dart';

Map<String, bool> redirected = const {};

class PersonalBloc extends Bloc<PersonalEvent, PersonalState> {
  final PersonalRepository _repository;
  PersonalBloc({
    required PersonalRepository repository,
  })  : _repository = repository,
        super(PersonalState(sessionId: repository.generateSessionId())) {
    on<DeleteMessage>(_deleteMessage);
    on<DeleteResponseOption>(_deleteResponseOption);
    on<UpdateToken>(_updateUserToken);
    on<FetchPersonalEvents>(_fetchActivatedStatus);
    on<FetchChatHistory>(_fetchChatHistory);
    on<Initialise>(_handleInitialise);
    on<FlushPersonal>(_flush);
    on<UpdateScrollPosition>(_updateScrollPosition);
    on<UpdateIsScrolling>(_updateIsScrolling);
    on<SendMessage>(_sendMessage);
    on<UpdateAnimatedStatus>(_updateAnimationStatus);
    on<UpdateComponentState>(_updateComponentState);
    on<FetchInstrument>(_fetchInstrument);
    on<UpdateMentorFormState>(_updateMentorFormState);
    on<UpdatePersonalState>(_updatePersonalState);
    on<UpdateScrollOffset>(_updateScrollOffset);
    on<QueueMessage>(_enquequeMessage);
    on<ClearQueue>(_clearQueue);
    on<SocketInsights>(_socketInsights);
    on<FetchCheatSheet>(_fetchCheatSheet);
    on<SaveMockPortfolio>(_saveMockPortfolio);
    on<ClearSavePortFolioErrorMessage>(_clearSavePortFolioErrorMessage);
  }

  FutureOr<void> _clearQueue(ClearQueue event, Emitter<PersonalState> emit) {
    emit(state.copyWith(messageQueue: []));
  }

  bool listenerAttached = false;

  void _enquequeMessage(QueueMessage event, Emitter<PersonalState> emit) {
    emit(state.copyWith(messageQueue: [...state.messageQueue, event.message]));
  }

  void _updateScrollOffset(
    UpdateScrollOffset event,
    Emitter<PersonalState> emit,
  ) =>
      emit(state.updateScrollOffset(event.offset));

  void _updatePersonalState(
    UpdatePersonalState event,
    Emitter<PersonalState> emit,
  ) {
    emit(event.state);
  }

  CheatSheet? cheatSheet;

  void _fetchCheatSheet(
    FetchCheatSheet event,
    Emitter<PersonalState> emit,
  ) async {
    cheatSheet = CheatSheet.parse(await MagnifiSanityService.instance
        .fetchData(r'''*[ _type == 'personalCheatSheet']{
                isCheatSheetVisible,
                text,
                children
             }'''));
  }

  void _updateComponentState(
    UpdateComponentState event,
    Emitter<PersonalState> emit,
  ) {
    try {
      final componentStates = Map.of(state.componentStates);
      final previousValue = state.getComponentState(event.uniqueKey);
      componentStates[event.uniqueKey] = {...previousValue, ...event.newValue};
      emit(state.copyWith(componentStates: componentStates));
    } catch (e) {
      log('error_updateComponentState $e', name: 'error_updateComponentState');
    }
  }

  void _updateAnimationStatus(
    UpdateAnimatedStatus event,
    Emitter<PersonalState> emit,
  ) {
    try {
      final offsets = Map.of(state.componentOffsets);
      offsets[event.uniqueKey] = event.status;
      emit(state.copyWith(componentOffsets: offsets));
    } catch (e) {
      log('error_updateAnimationStatus $e',
          name: 'error_updateAnimationStatus');
    }
  }

  void _updateIsScrolling(
    UpdateIsScrolling event,
    Emitter<PersonalState> emit,
  ) {
    emit(state.copyWith(isScrolling: event.isScrolling));
  }

  void _updateScrollPosition(
    UpdateScrollPosition event,
    Emitter<PersonalState> emit,
  ) {
    emit(state.copyWith(scrollPosition: event.position));
  }

  void _updateUserToken(
    UpdateToken event,
    Emitter<PersonalState> emit,
  ) async {
    emit(state.copyWith(token: event.token));
  }

  Future<void> _fetchActivatedStatus(
    FetchPersonalEvents event,
    Emitter<PersonalState> emit,
  ) async {
    emit(state.copyWith(loading: true));

    await _repository.getEvents(state.token);

    emit(state.copyWith(loading: false));
    await emit.forEach(
      _repository.eventStream,
      onData: (event) => state.copyWith(events: event),
    );
  }

  Future<void> _fetchChatHistory(
    FetchChatHistory event,
    Emitter<PersonalState> emit,
  ) async {
    if (state.fetchingHistory || !state.hasMoreMessages) return;

    emit(state.copyWith(userId: event.userId, fetchingHistory: true));

    final nextToken = await _repository.getChatHistory(
        MagnifiStorage.authToken, state.nextToken);
    emit(state.copyWith(
      hasMoreMessages: nextToken != null && nextToken.isNotEmpty,
      fetchingHistory: false,
    ));
  }

  Future _sendMessage(SendMessage event, Emitter<PersonalState> emit) async {
    emit(state.copyWith(scrollOffset: 0.0));
    await _repository.sendMessage(
      event.message,
      MagnifiStorage.authToken,
      state.sessionId,
      hidden: event.hidden ??
          (event.message.startsWith("---") || event.message.endsWith("---")),
      source: event.source,
      sourceId: event.sourceId,
      trackColdStart: (event, properties) {
        if (state.isColdStartFlow) {
          MagnifiAnalytics.track(
            event,
            properties: properties,
          );
        }
      },
    );
    emit(state.copyWith(scrollOffset: null));
    try {
      final responseOption = state.responseOptiosn.map((e) => e.label).toList();
      final tickers = state.chatlist
          .map((e) {
            final tickers = <String>[];
            final isAnyPrompt = [
              MentorChatType.tradeprompt,
              MentorChatType.wlprompt
            ].contains(e.type);
            if (isAnyPrompt) {
              tickers.addAll(e.data is MentorTradePromptData
                  ? (e.data as MentorTradePromptData).items.map((e) => e.ticker)
                  : e.data is MentorWatchlistPromptData
                      ? (e.data as MentorWatchlistPromptData)
                          .items
                          .map((e) => e.ticker)
                      : []);
            } else if (e is MentorPowerTable) {
              tickers.addAll(e.data.data.map((e) => e.label));
            } else if (e is MentorCustomTable) {
              tickers.addAll(e.data.data.map((e) => e.label));
            }
            return tickers;
          })
          .toList()
          .reduce((value, element) => [...value, ...element]);
      final selectedOption = state.options?.options
          ?.firstWhereOrNull((e) => e.label?.toLowerCase() == event.message);
      MagnifiAnalytics.track(Event.mentorInteraction, properties: {
        "source": event.source,
        "last_chat": state.chatlist
            .where((e) => e.source == MentorChatSource.user)
            .whereType<MentorChatText>()
            .firstOrNull
            ?.data
            .text,
        "ask_mentor_query":
            event.message.isEmpty ? 'not_applicable' : event.message,
        'tickers_displayed_last_interaction':
            tickers.isEmpty ? 'not_applicable' : tickers,
        'event_clicked':
            event.message.isEmpty ? 'not_applicable' : event.message,
        'response_displayed':
            responseOption.isEmpty ? 'not_applicable' : responseOption,
        'response_selected': selectedOption ?? 'not_applicable',
      });
    } catch (e) {}
  }

  void _updateMentorFormState(
    UpdateMentorFormState event,
    Emitter<PersonalState> emit,
  ) {
    final currentState = Map.from(state.personalFormStates);
    emit(state.copyWith(
      personalFormStates: {...currentState, event.uniqueKey: event.state},
    ));
  }

  Future _fetchInstrument(
      FetchInstrument event, Emitter<PersonalState> emit) async {
    await _repository.fetchInstrument(event.ticker);
  }

  void _deleteMessage(DeleteMessage event, Emitter<PersonalState> emit) {
    _repository.deleteMessage(event.chat);
  }

  FutureOr<void> _deleteResponseOption(
    DeleteResponseOption event,
    Emitter<PersonalState> emit,
  ) {
    _repository.deleteResponseOption(event.option);
  }

  void _flush(FlushPersonal event, Emitter<PersonalState> emit) {
    _repository.flush();
    emit(
      PersonalState(
        sessionId: _repository.generateSessionId(),
        nextToken: null,
      ),
    );
  }

  void _handleInitialise(Initialise event, Emitter<PersonalState> emit) async {
    if (!listenerAttached) {
      listenerAttached = true;
      final combined = Rx.combineLatest7(
        _repository.nextTokenStream,
        _repository.chatlistStream,
        _repository.optionsSream,
        _repository.instrumentPoolStream,
        _repository.instrumentFetchStatusStream,
        _repository.introChatStream,
        _repository.firstTimeMpUserStream,
        ($1, $2, $3, $4, $5, $6, $7) => (
          nextToken: $1,
          chatList: $2,
          options: $3,
          instrumentPool: $4,
          instrumentFetchStatus: $5,
          introChat: $6,
          firstTimeMpUser: $7
        ),
      );

      await emit.forEach(
        combined,
        onData: (data) {
          final chatList = data.chatList;
          final hasValidEntry = chatList.isNotEmpty;
          final nextToken = data.nextToken;
          final responseOptions = data.options;
          final instrumentPool = data.instrumentPool;
          final instrumentFetchStatus = data.instrumentFetchStatus;
          final introChat = data.introChat;
          final firstTimeMpUser = data.firstTimeMpUser;

          if (!(responseOptions.disabled) &&
              (responseOptions.options?.any((e) => e.redirect ?? false) ??
                  false)) {
            final option = (responseOptions.options ?? [])
                .firstWhereOrNull((e) => e.redirect ?? false);
            if (option != null) handleSearchTrigger(option);
          }
          return state.copyWith(
            nextToken: nextToken,
            chatlist: hasValidEntry ? chatList : null,
            options: responseOptions.copyWith(
              options: responseOptions.options
                  ?.where((e) => e.redirect ?? false)
                  .toList(),
            ),
            instrumentPool: instrumentPool,
            instrumentFetchStatus: instrumentFetchStatus,
            introChat: introChat,
            mentorFirstTimeMpUser: firstTimeMpUser,
          );
        },
        onError: (error, stackTrace) {
          MagnifiSentryService.captureException(error, stackTrace);
          return state;
        },
      );
    }
  }

  FutureOr<void> _socketInsights(
    SocketInsights event,
    Emitter<PersonalState> emit,
  ) async {
    await _repository.fetchSocketInsightEvents(
      MagnifiStorage.authToken,
      EnvironmentConfig.insightsSocketUrl,
    );

    try {
      await emit.forEach(_repository.socketEventStream, onData: (data) {
        final oE = state.events;
        final communities =
            mergeMentorEventList(oE?.communities, data?.communities);
        final enhancements =
            mergeMentorEventList(oE?.enhancements, data?.enhancements);
        final toolsNTips =
            mergeMentorEventList(oE?.toolsNTips, data?.toolsNTips);
        final financialGoals =
            mergeMentorEventList(oE?.financialGoals, data?.financialGoals);
        final marketsNMacro =
            mergeMentorEventList(oE?.marketsNMacro, data?.marketsNMacro);
        return state.copyWith(
          events: MentorEvents(
            enhancements: enhancements,
            toolsNTips: toolsNTips,
            financialGoals: financialGoals,
            marketsNMacro: marketsNMacro,
            communities: communities,
          ),
        );
      });
    } catch (e) {
      prettyLogger(e, name: 'Insights Socket Error');
    }
  }

  FutureOr<void> _saveMockPortfolio(
      SaveMockPortfolio event, Emitter<PersonalState> emit) async {
    emit(state.copyWith(loading: true));
    try {
      final message = await _repository.saveMockPortfolio(
          event.value, event.name, event.tickers, MagnifiStorage.authToken);
      emit(state.copyWith(savePortfolioErrorMessage: message ?? ''));

      if (message == null) {
        event.navigator();
        add(UpdateComponentState(
          event.uniqueKey,
          const {'disableSavePortFolioButton': true},
        ));
      }
      emit(state.copyWith(loading: false));
    } catch (e) {
      emit(state.copyWith(loading: false));
    }
  }

  String? extractLastUserMessage() {
    final userMessages = state.chatlist
        .where((e) => e.source == MentorChatSource.user)
        .whereType<MentorChatText>();
    return userMessages.lastOrNull?.data.text;
  }

  FutureOr<void> _clearSavePortFolioErrorMessage(
      ClearSavePortFolioErrorMessage event, Emitter<PersonalState> emit) {
    emit(state.copyWith(savePortfolioErrorMessage: ''));
  }
}

void handleSearchTrigger(ResponseOption option) {
  final bloc = navigator.currentContext!.read<PersonalBloc>();
  bloc.add(DeleteResponseOption(option));
  final searchProvider = navigator.currentContext!.read<SearchProvider>();
  searchProvider.search(Uri.decodeComponent(option.query!));
  searchProvider.resetSortAndFilter();
  if (NavigationService.currrentPath != Routes.app) {
    NavigationService.popUntil(Routes.app);
  }
  NavigationService.pushNamed(Routes.searchResults,
      args: Uri.decodeComponent(option.query!));
}

List<MentorEvent> mergeMentorEventList([
  List<MentorEvent>? prev = const [],
  List<MentorEvent>? curr = const [],
]) {
  final mergedMap = <String, MentorEvent>{};
  final merged = [...?prev, ...?curr];

  for (final event in merged) {
    final key = event.cta_data?.actionData;
    if (key == null) continue;
    mergedMap[key] = event;
  }

  return mergedMap.values.toList();
}
