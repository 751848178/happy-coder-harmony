part of 'search_screen.dart';

Widget _buildSessionSearchScaffold(_SessionSearchScreenState state) {
  final (sessions, isLoading) = state.ref.watch(sessionStateProvider.select(
    (s) {
      var sessions = <Session>[];
      var loading = false;
      s.whenOrNull(
        ready: (sMap, _, __) {
          sessions = sMap.values.toList();
        },
        loading: () {
          loading = true;
        },
      );
      return (sessions, loading);
    },
  ));
  return Scaffold(
    backgroundColor: AppTheme.surface,
    appBar: AppBar(
      backgroundColor: AppTheme.surface,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(state.context),
      ),
      title: const Text('搜索会话'),
    ),
    body: Column(
      children: [
        _buildSessionSearchBar(state),
        Expanded(
            child:
                _buildSessionSearchResults(state, sessions, isLoading)),
      ],
    ),
  );
}

Widget _buildSessionSearchBar(_SessionSearchScreenState state) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppTheme.surface,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: TextField(
      controller: state._searchController,
      focusNode: state._searchFocusNode,
      onChanged: state._performSearch,
      decoration: InputDecoration(
        hintText: '搜索会话或消息...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: state._searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  state._searchController.clear();
                  state._performSearch('');
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: AppTheme.neutral50,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
  );
}

Widget _buildSessionSearchResults(
    _SessionSearchScreenState state, List<Session> sessions, bool isLoading) {
  if (isLoading) {
    return const Center(child: CircularProgressIndicator());
  }
  if (sessions.isEmpty) {
    return _buildSessionSearchEmptyState(state);
  }
  return ListView.builder(
    padding: const EdgeInsets.all(8),
    itemCount: sessions.length,
    itemBuilder: (context, index) =>
        _buildSessionSearchCard(state.context, sessions[index]),
  );
}

Widget _buildSessionSearchEmptyState(_SessionSearchScreenState state) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.search_off, size: 64, color: AppTheme.neutral400),
        const SizedBox(height: 16),
        Text(
          state._isSearching ? '没有找到匹配的结果' : '输入关键词开始搜索',
          style: TextStyle(fontSize: 16, color: AppTheme.neutral600),
        ),
        const SizedBox(height: 8),
        Text(
          '搜索会话标题或消息内容',
          style: TextStyle(fontSize: 14, color: AppTheme.neutral400),
        ),
      ],
    ),
  );
}

Widget _buildSessionSearchCard(BuildContext context, Session session) {
  return Card(
    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
    child: ListTile(
      leading: CircleAvatar(
        backgroundColor: AppTheme.brandColor.withValues(alpha: 0.2),
        child: Text(
          session.title.isNotEmpty ? session.title[0].toUpperCase() : '?',
          style: const TextStyle(
              color: AppTheme.brandColor, fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(session.title,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(_formatSessionSearchDate(session.updatedAt),
          style: TextStyle(color: AppTheme.neutral500, fontSize: 12)),
      onTap: () => context.push('/session/${session.id}'),
    ),
  );
}
