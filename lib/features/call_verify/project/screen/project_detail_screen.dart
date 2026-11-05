
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../call_log/call_log.dart';
import '../controller/project_controller.dart';
import '../model/project_model.dart';

class ProjectDetailScreen extends StatefulWidget {
  const ProjectDetailScreen({super.key});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  static const Color _primaryRed = Color(0xFFD71920);
  static const Color _bg = Color(0xFFF7F7F7);
  static const Color _textBlack = Color(0xFF222222);
  static const Color _textGrey = Color(0xFF777777);
  static const Color _borderGrey = Color(0xFFE8E8E8);
  static const Color _green = Color(0xFF38A852);
  static const Color _greenBg = Color(0xFFE7F5E9);
  static const Color _orange = Color(0xFFFFA000);
  static const Color _orangeBg = Color(0xFFFFF5DC);

  late final ProjectController controller;
  late final Survey survey;
  late final String surveyId;

  final TextEditingController _searchController = TextEditingController();
  final Map<String, TextEditingController> _fieldControllers = {};

  final ScrollController _scrollController = ScrollController();

  bool _filtersExpanded = false;
  bool _fieldFiltersExpanded = false;
  bool _isApplyingFilter = false;

  String _selectedStatus = 'All';
  String _selectedPeriod = '';

  // Selected field/value are populated from API 2 metadata.
  String? _selectedField;
  String? _selectedFieldValue;

  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();

    survey = Get.arguments as Survey;
    surveyId = survey.surveyId;

    controller = Get.isRegistered<ProjectController>(tag: 'project')
        ? Get.find<ProjectController>(tag: 'project')
        : Get.put(ProjectController(), tag: 'project');

    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (surveyId.isEmpty) {
        Get.snackbar(
          'Survey unavailable',
          'The survey ID is missing. Please go back and open the survey again.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      if (controller.getResponses(surveyId) == null) {
        controller.loadSurveyResponses(surveyId, reset: true);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();

    for (final textController in _fieldControllers.values) {
      textController.dispose();
    }

    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 250) {
      if (controller.hasMoreResponses(surveyId) &&
          !controller.isLoadingMore(surveyId) &&
          !controller.isSurveyLoading(surveyId)) {
        controller.loadMoreResponses(surveyId);
      }
    }
  }

  String _dateString(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _displayDate(DateTime? date) {
    if (date == null) return 'Select date';

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Future<void> _pickDate({required bool isFromDate}) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: isFromDate
          ? (_fromDate ?? DateTime.now())
          : (_toDate ?? _fromDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _primaryRed,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: _textBlack,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selected == null) return;

    setState(() {
      if (isFromDate) {
        _fromDate = selected;

        if (_toDate != null && _toDate!.isBefore(selected)) {
          _toDate = null;
        }
      } else {
        _toDate = selected;
      }

      _selectedPeriod = '';
    });

    _applyFilters();
  }

  Future<void> _applyFilters() async {
    if (_isApplyingFilter) return;

    setState(() => _isApplyingFilter = true);

    final Map<String, dynamic> filters = {};
    final selectedField = _selectedField;
    final selectedValue = _selectedFieldValue;

    if (selectedField != null &&
        selectedField.isNotEmpty &&
        selectedValue != null &&
        selectedValue.isNotEmpty) {
      filters[selectedField] = selectedValue;
    }

    try {
      await controller.applyResponseFilters(
        surveyId: surveyId,
        search: _searchController.text.trim(),
        period: _selectedPeriod,
        fromDate: _fromDate == null ? '' : _dateString(_fromDate!),
        toDate: _toDate == null ? '' : _dateString(_toDate!),
        filters: filters,
      );
    } finally {
      if (mounted) {
        setState(() => _isApplyingFilter = false);
      }
    }
  }

  Future<void> _selectQuickPeriod(String period) async {
    setState(() {
      _selectedPeriod = period;
      _fromDate = null;
      _toDate = null;
    });

    await _applyFilters();
  }

  Future<void> _clearFilters() async {
    _searchController.clear();

    for (final textController in _fieldControllers.values) {
      textController.clear();
    }

    setState(() {
      _selectedPeriod = '';
      _selectedStatus = 'All';
      _selectedField = null;
      _selectedFieldValue = null;
      _fromDate = null;
      _toDate = null;
    });

    await controller.clearFilters(surveyId);
  }

  String _fieldLabel(String value) {
    return value
        .replaceAll('_', ' ')
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  String _responseStatus(SurveyResponse response) {
    final status = response.lastCall?.status.trim() ?? '';

    if (status.isEmpty) return 'Not Called';

    return status;
  }

  bool _matchesStatus(SurveyResponse response) {
    if (_selectedStatus == 'All') return true;

    return _responseStatus(response).toLowerCase() ==
        _selectedStatus.toLowerCase();
  }

  Color _statusColor(String status) {
    final value = status.toLowerCase();

    if (value.contains('correct') ||
        value.contains('passed') ||
        value.contains('pass')) {
      return _green;
    }

    if (value.contains('not pick') ||
        value.contains('pending') ||
        value.contains('not called')) {
      return _orange;
    }

    return _primaryRed;
  }

  Color _statusBackground(String status) {
    final value = status.toLowerCase();

    if (value.contains('correct') ||
        value.contains('passed') ||
        value.contains('pass')) {
      return _greenBg;
    }

    if (value.contains('not pick') ||
        value.contains('pending') ||
        value.contains('not called')) {
      return _orangeBg;
    }

    return _lightRedBg;
  }

  static const Color _lightRedBg = Color(0xFFFDECEC);


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Obx(() {
          // Get response list from controller
          final List<SurveyResponse> responses =
          controller.getSurveyResponses(surveyId);

          // Apply status filter
          final visibleResponses =
          responses.where(_matchesStatus).toList();

          // Get total records from API
          final int total =
          controller.getTotalResponses(surveyId);

          final bool isLoading =
          controller.isSurveyLoading(surveyId);

          final bool isLoadingMore =
          controller.isLoadingMore(surveyId);

          final String? error =
          controller.getResponseError(surveyId);

          return RefreshIndicator(
            color: _primaryRed,
            onRefresh: () =>
                controller.refreshSurveyResponses(surveyId),
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
              children: [
                // Advanced Filters
                _buildAdvancedFilters(),

                const SizedBox(height: 16),

                // Status Filter
                _buildStatusSummary(
                  visibleResponses,
                  total,
                ),

                const SizedBox(height: 14),

                // Clear All Filters
                _buildClearFiltersButton(),

                const SizedBox(height: 14),

                // Total Records
                _buildRecordSummary(
                  visibleResponses.length,
                  total,
                ),

                const SizedBox(height: 14),

                // Initial Loading
                if (isLoading && responses.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 50),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: _primaryRed,
                      ),
                    ),
                  )

                // API Error
                else if (error != null && responses.isEmpty)
                  _buildErrorState(error)

                // Empty Response
                else if (visibleResponses.isEmpty)
                    _buildEmptyState()

                  // Response List
                  else ...[
                      ...visibleResponses.map(
                            (response) =>
                            _buildExpandableResponseCard(response),
                      ),

                      // Loading More
                      if (isLoadingMore)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 18),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: _primaryRed,
                            ),
                          ),
                        ),

                      // End of List
                      if (!controller.hasMoreResponses(surveyId))
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: Center(
                            child: Text(
                              'You have reached the end',
                              style: TextStyle(
                                fontSize: 11,
                                color: _textGrey,
                              ),
                            ),
                          ),
                        ),
                    ],
              ],
            ),
          );
        }),
      ),
    );
  }


  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _primaryRed,
      foregroundColor: Colors.white,
      elevation: 0,
      toolbarHeight: 68,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        onPressed: () => Get.back(),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            survey.surveyTitle.isEmpty ? 'Survey' : survey.surveyTitle,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Text(
            'Survey Responses',
            style: TextStyle(
              fontSize: 11,
              color: Colors.white70,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(
                Icons.refresh_rounded,
                size: 22,
                color: Colors.white,
              ),
              onPressed: () {
                controller.refreshSurveyResponses(surveyId);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdvancedFilters() {
    // API 2 is the source of truth. API 1 may return an empty fields array.
    final responseData = controller.getResponses(surveyId);
    final fields = responseData?.fields ?? <String>[];
    final selectedField = _selectedField;
    final fieldValues = selectedField == null
        ? <String>[]
        : (responseData?.fieldValues[selectedField] ?? <String>[]);
    final uniqueFieldValues = fieldValues.toSet().toList();
    final selectedFieldIsValid =
        selectedField != null && fields.contains(selectedField);
    final selectedValueIsValid = _selectedFieldValue != null &&
        uniqueFieldValues.contains(_selectedFieldValue);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() => _filtersExpanded = !_filtersExpanded);
            },
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.all(13),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: _primaryRed,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(
                      Icons.filter_alt_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Advanced Filters',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _textBlack,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Search and filter survey responses',
                          style: TextStyle(
                            fontSize: 10,
                            color: _textGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _bg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Text(
                          '${fields.length} fields',
                          style: const TextStyle(
                            fontSize: 10,
                            color: _textGrey,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          _filtersExpanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          size: 17,
                          color: _textGrey,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_filtersExpanded) ...[
            const Divider(height: 1, color: _borderGrey),
            Padding(
              padding: const EdgeInsets.all(13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionHeading(
                    Icons.search_rounded,
                    'Search Responses',
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _searchController,
                    onSubmitted: (_) => _applyFilters(),
                    decoration: InputDecoration(
                      hintText: 'Search mobile number or answers...',
                      hintStyle: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: _textGrey,
                        size: 20,
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search, color: _primaryRed),
                        onPressed: _applyFilters,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFFAFAFA),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _borderGrey),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _borderGrey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _primaryRed),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  _sectionHeading(
                    Icons.calendar_month_rounded,
                    'Survey Creation Date',
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _dateBox(
                          'FROM',
                          _fromDate,
                              () => _pickDate(isFromDate: true),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                          color: Colors.grey,
                        ),
                      ),
                      Expanded(
                        child: _dateBox(
                          'TO',
                          _toDate,
                              () => _pickDate(isFromDate: false),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      _quickDateButton('Today', 'today'),
                      _quickDateButton('Yesterday', 'yesterday'),
                      _quickDateButton('This Week', 'this_week'),
                      _quickDateButton('This Month', 'this_month'),
                    ],
                  ),

                  const SizedBox(height: 18),

                  _sectionHeading(
                    Icons.tune_rounded,
                    'Filter by Survey Fields',
                  ),

                  const SizedBox(height: 8),

                  InkWell(
                    onTap: () {
                      setState(() {
                        _fieldFiltersExpanded = !_fieldFiltersExpanded;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAFAFA),
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(color: _borderGrey),
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Select survey fields to filter',
                              style: TextStyle(
                                fontSize: 12,
                                color: _textGrey,
                              ),
                            ),
                          ),
                          Icon(
                            _fieldFiltersExpanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: _textGrey,
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (_fieldFiltersExpanded) ...[
                    const SizedBox(height: 10),
                    if (fields.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAFAFA),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _borderGrey),
                        ),
                        child: const Text(
                          'Survey fields are not available yet. Please refresh responses.',
                          style: TextStyle(fontSize: 11, color: _textGrey),
                        ),
                      )
                    else ...[
                      DropdownButtonFormField<String>(
                        value: selectedFieldIsValid ? _selectedField : null,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Select Survey Field',
                          hintText: 'Choose a field',
                          labelStyle: const TextStyle(fontSize: 12),
                          hintStyle: const TextStyle(fontSize: 11),
                          isDense: true,
                          filled: true,
                          fillColor: const Color(0xFFFAFAFA),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: _borderGrey),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: _borderGrey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: _primaryRed),
                          ),
                        ),
                        items: fields.toSet().map((field) {
                          return DropdownMenuItem<String>(
                            value: field,
                            child: Text(
                              _fieldLabel(field),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedField = value;
                            _selectedFieldValue = null;
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: selectedValueIsValid ? _selectedFieldValue : null,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Select Value',
                          hintText: !selectedFieldIsValid
                              ? 'Select a field first'
                              : uniqueFieldValues.isEmpty
                              ? 'No values available for this field'
                              : 'Choose a value',
                          labelStyle: const TextStyle(fontSize: 12),
                          hintStyle: const TextStyle(fontSize: 11),
                          isDense: true,
                          filled: true,
                          fillColor: const Color(0xFFFAFAFA),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: _borderGrey),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: _borderGrey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: _primaryRed),
                          ),
                        ),
                        items: uniqueFieldValues.map((value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(
                              value.trim().isEmpty ? '(Empty value)' : value,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: !selectedFieldIsValid ||
                            uniqueFieldValues.isEmpty
                            ? null
                            : (value) {
                          setState(() {
                            _selectedFieldValue = value;
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isApplyingFilter ||
                              !selectedFieldIsValid ||
                              !selectedValueIsValid
                              ? null
                              : _applyFilters,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryRed,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey.shade300,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('Apply Field Filter'),
                        ),
                      ),
                    ],
                  ],

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isApplyingFilter ? null : _applyFilters,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryRed,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(11),
                        ),
                      ),
                      child: _isApplyingFilter
                          ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                          : const Text(
                        'Apply Filters',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionHeading(IconData icon, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: _lightRedBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: _primaryRed),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: _textBlack,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _dateBox(
      String label,
      DateTime? date,
      VoidCallback onTap,
      ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: _borderGrey),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 9,
                color: _textGrey,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 9),
            Row(
              children: [
                Expanded(
                  child: Text(
                    date == null ? 'Select date' : _displayDate(date),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: date == null ? Colors.grey : _textBlack,
                    ),
                  ),
                ),
                const Icon(
                  Icons.calendar_today_rounded,
                  size: 14,
                  color: _textGrey,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickDateButton(String label, String value) {
    final selected = _selectedPeriod == value;

    return InkWell(
      onTap: () => _selectQuickPeriod(value),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 13,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: selected ? _primaryRed : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? _primaryRed : _borderGrey,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : _textBlack,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusSummary(
      List<SurveyResponse> responses,
      int total,
      ) {
    final statusOptions = <String>{'All'};

    for (final response in responses) {
      statusOptions.add(_responseStatus(response));
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: _greenBg,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: _green,
                  size: 18,
                ),
              ),
              const SizedBox(width: 9),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Filter by Status',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _textBlack,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Choose response call status',
                      style: TextStyle(
                        fontSize: 10,
                        color: _textGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: _borderGrey),
              borderRadius: BorderRadius.circular(11),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: statusOptions.contains(_selectedStatus)
                    ? _selectedStatus
                    : 'All',
                isExpanded: true,
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: _textGrey,
                ),
                style: const TextStyle(
                  fontSize: 12,
                  color: _textBlack,
                ),
                items: statusOptions.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(
                      status == 'All' ? 'All Statuses' : status,
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _selectedStatus = value);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClearFiltersButton() {
    return InkWell(
      onTap: _clearFilters,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _primaryRed),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.filter_alt_off_rounded,
              size: 16,
              color: _primaryRed,
            ),
            SizedBox(width: 7),
            Text(
              'Clear All Filters',
              style: TextStyle(
                color: _primaryRed,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordSummary(int visible, int total) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: _lightRedBg,
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: _primaryRed,
              size: 19,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Records',
                  style: TextStyle(
                    fontSize: 10,
                    color: _textGrey,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$total',
                  style: const TextStyle(
                    fontSize: 18,
                    color: _textBlack,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Showing $visible on this page',
                  style: const TextStyle(
                    fontSize: 9,
                    color: _textGrey,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 9,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: _orangeBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(Icons.circle, color: _orange, size: 7),
                SizedBox(width: 5),
                Text(
                  'Records',
                  style: TextStyle(
                    color: _orange,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableResponseCard(SurveyResponse response) {
    final tileController = ExpansionTileController();
    final status = _responseStatus(response);
    final statusColor = _statusColor(status);
    final statusBg = _statusBackground(status);

    final name = response.name.trim().isEmpty
        ? 'Unknown'
        : response.name;

    final candidate = response.candidate.trim().isEmpty
        ? '—'
        : response.candidate;

    final answerCount = response.answers.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 9,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          controller: tileController,
          tilePadding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
          childrenPadding: const EdgeInsets.fromLTRB(13, 0, 13, 14),
          showTrailingIcon: false,
          title: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(
                          color: statusColor.withOpacity(0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.circle,
                            size: 7,
                            color: statusColor,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              status,
                              style: TextStyle(
                                fontSize: 10,
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 9),

                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: _primaryRed,
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Text(
                            response.responseId.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: _textBlack,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Pass Fail: ${response.passFailStatus}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: _primaryRed,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    _buildCollapsedInfoRow('Name', name),
                    _buildCollapsedInfoRow('Candidate', candidate),

                    if (response.phone.isNotEmpty)
                      _buildPhoneRow(response),

                    const SizedBox(height: 9),

                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _bg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _borderGrey),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.add_circle_outline,
                              size: 12,
                              color: _textGrey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '+${answerCount > 3 ? answerCount - 3 : 0} more fields',
                              style: const TextStyle(
                                fontSize: 10,
                                color: _textGrey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 9),

              AnimatedBuilder(
                animation: tileController,
                builder: (context, child) {
                  final expanded = tileController.isExpanded;

                  return InkWell(
                    onTap: () {
                      if (expanded) {
                        tileController.collapse();
                      } else {
                        tileController.expand();
                      }
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: expanded ? _primaryRed : _bg,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: expanded ? _primaryRed : _borderGrey,
                        ),
                      ),
                      child: Icon(
                        expanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        size: 19,
                        color: expanded ? Colors.white : _primaryRed,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),

          children: [
            const Divider(color: _borderGrey, height: 1),
            const SizedBox(height: 12),

            _buildDetailedRow('Response ID', response.responseId.toString()),

            ...response.answers.entries.map((entry) {
              return _buildDetailedRow(
                _fieldLabel(entry.key),
                SurveyResponse.formatAnswer(entry.value),
              );
            }),

            _buildDetailedRow(
              'Created At',
              _formatDateTime(response.createdAt),
            ),

            if (response.lastCall != null) ...[
              const SizedBox(height: 5),
              _buildDetailedRow(
                'Call Status',
                response.lastCall!.status,
              ),
              _buildDetailedRow(
                'Caller',
                response.lastCall!.callerName,
              ),
              _buildDetailedRow(
                'Last Call',
                _formatDateTime(response.lastCall!.createdAt),
              ),
              _buildDetailedRow(
                'Call Duration',
                response.lastCall!.formattedDuration,
              ),
            ],

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(text: response.responseId.toString()),
                      );

                      Get.snackbar(
                        'Copied',
                        'Response ID copied successfully.',
                        snackPosition: SnackPosition.BOTTOM,
                        duration: const Duration(seconds: 2),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded, size: 15),
                    label: const Text('Copy ID'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _textGrey,
                      side: const BorderSide(color: _borderGrey),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                if (response.phone.isNotEmpty)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _startCall(response),
                      icon: const Icon(Icons.call_rounded, size: 15),
                      label: const Text('Call Now'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryRed,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneRow(SurveyResponse response) {
    return Padding(
      padding: const EdgeInsets.only(top: 7),
      child: Row(
        children: [
          const SizedBox(
            width: 65,
            child: Text(
              'Mobile',
              style: TextStyle(
                fontSize: 10,
                color: _textGrey,
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => _startCall(response),
              child: Row(
                children: [
                  const Icon(
                    Icons.call_rounded,
                    size: 12,
                    color: _primaryRed,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    response.phone,
                    style: const TextStyle(
                      fontSize: 11,
                      color: _primaryRed,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsedInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 65,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: _textGrey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                color: _textBlack,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              label.isEmpty ? ' ' : label,
              style: const TextStyle(
                fontSize: 11,
                color: _textGrey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: const TextStyle(
                fontSize: 12,
                color: _textBlack,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.inbox_rounded,
            size: 42,
            color: _textGrey,
          ),
          SizedBox(height: 10),
          Text(
            'No responses found',
            style: TextStyle(
              fontSize: 14,
              color: _textBlack,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Try changing or clearing your filters.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: _textGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: _primaryRed,
            size: 35,
          ),
          const SizedBox(height: 10),
          Text(
            error,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: _textGrey,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              controller.refreshSurveyResponses(surveyId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Future<void> _startCall(SurveyResponse response) async {
    final phone = response.phone.trim();

    if (phone.isEmpty) {
      Get.snackbar(
        'Phone number unavailable',
        'This response does not have a phone number.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: const Row(
          children: [
            Icon(Icons.phone_in_talk_rounded, color: _primaryRed),
            SizedBox(width: 10),
            Expanded(child: Text('Make a call?')),
          ],
        ),
        content: Text(
          'Do you want to call this number?\n\n$phone',
          style: const TextStyle(fontSize: 15, height: 1.4),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        actions: [
          OutlinedButton(
            onPressed: () => Get.back<bool>(result: false),
            style: OutlinedButton.styleFrom(
              foregroundColor: _textBlack,
              side: const BorderSide(color: _borderGrey),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () => Get.back<bool>(result: true),
            icon: const Icon(Icons.call_rounded, size: 18),
            label: const Text('Make Call'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryRed,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
      barrierDismissible: false,
    );

    if (confirmed != true) return;

    if (!Get.isRegistered<CallLog>()) {
      Get.snackbar(
        'Call service unavailable',
        'Call tracking has not been initialized. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      final callLog = Get.find<CallLog>();

      final started = await callLog.startCall(
        responseId: response.responseId,
        phoneNumber: phone,
      );

      if (!started) {
        Get.snackbar(
          'Unable to start call',
          'The call could not be started. Check phone-call permissions and try again.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Call error',
        'Unable to start this call. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  String _formatDateTime(String iso) {
    if (iso.isEmpty) return '—';

    try {
      final dt = DateTime.parse(iso);

      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];

      return '${months[dt.month - 1]} ${dt.day}, ${dt.year} · '
          '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}