import 'package:choco/app/colors.dart';
import 'package:flutter/material.dart';

class DateRangePicker extends StatefulWidget {
  final Function(DateTime?, DateTime?) onDateSelected;

  const DateRangePicker({super.key, required this.onDateSelected});

  @override
  State<DateRangePicker> createState() => _DateRangePickerState();
}

class _DateRangePickerState extends State<DateRangePicker> {
  DateTime? _start;
  DateTime? _end;

  String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 🔹 FECHA INICIO
        Expanded(
          child: Card(
            color: AppColors.primary,
            child: ListTile(
              leading: const Icon(Icons.calendar_today, color: AppColors.text),
              title: Text(
                _start != null ? formatDate(_start!) : 'Fecha inicio',
                style: TextStyle(
                  color: AppColors.text,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );

                if (d != null) {
                  setState(() => _start = d);
                  widget.onDateSelected(_start, _end);
                }
              },
            ),
          ),
        ),

        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Icon(Icons.arrow_forward),
        ),

        // 🔹 FECHA FIN
        Expanded(
          child: Card(
            color: AppColors.primary,
            child: ListTile(
              leading: const Icon(Icons.calendar_today, color: AppColors.text),
              title: Text(
                _end != null ? formatDate(_end!) : 'Fecha fin',
                style: TextStyle(
                  color: AppColors.text,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _start ?? DateTime.now(),
                  firstDate: _start ?? DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );

                if (d != null) {
                  setState(() => _end = d);
                  widget.onDateSelected(_start, _end); // 🔥 clave
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}
