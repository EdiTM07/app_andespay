import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app_banco/core/constants/app.colors.dart';
import 'package:app_banco/features/transfers/models/transaction.model.dart';

class ExpensesChartWidget extends StatelessWidget {
  final List<TransactionModel> transactions;

  const ExpensesChartWidget({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    // Filtrar solo débitos y agrupar por concepto
    final Map<String, double> expensesByConcept = {};
    double totalExpenses = 0;

    for (var t in transactions) {
      if (t.isDebit) {
        final concept = (t.concept == null || t.concept!.trim().isEmpty)
            ? 'Otros'
            : t.concept!.trim();
        expensesByConcept[concept] = (expensesByConcept[concept] ?? 0) + t.amount;
        totalExpenses += t.amount;
      }
    }

    if (expensesByConcept.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(Icons.pie_chart_outline_rounded,
                size: 48, color: AppColors.textSecondary.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text(
              'No hay gastos recientes',
              style: GoogleFonts.poppins(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    // Convertir a PieChartSectionData
    final colors = [
      AppColors.primary,
      const Color(0xFF26A69A), // Teal
      AppColors.accent, // Naranja
      AppColors.error, // Rojo
      AppColors.info, // Azul
      Colors.purple,
      Colors.indigo,
    ];

    int colorIndex = 0;
    final sections = expensesByConcept.entries.map((e) {
      final percentage = (e.value / totalExpenses) * 100;
      final color = colors[colorIndex % colors.length];
      colorIndex++;

      return PieChartSectionData(
        color: color,
        value: e.value,
        title: '${percentage.toStringAsFixed(0)}%',
        radius: 50,
        titleStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Distribución de Gastos',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: sections,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: expensesByConcept.entries.map((e) {
              final color = colors[expensesByConcept.keys.toList().indexOf(e.key) % colors.length];
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${e.key} (\$${e.value.toStringAsFixed(2)})',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
