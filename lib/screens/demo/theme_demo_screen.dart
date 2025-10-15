import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../theme/gradient_widgets.dart';

/// Demo screen showcasing Material Design 3 theming with custom styling
/// Demonstrates gradients, bold dark colors, large typography, rounded corners, and dark shadows
class ThemeDemoScreen extends StatefulWidget {
  const ThemeDemoScreen({super.key});

  @override
  State<ThemeDemoScreen> createState() => _ThemeDemoScreenState();
}

class _ThemeDemoScreenState extends State<ThemeDemoScreen> {
  bool _switchValue = true;
  double _sliderValue = 0.5;
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF121212), Color(0xFF1E1E1E)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom gradient app bar
              GradientAppBar(
                title: 'Material Design 3 Theme',
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A237E), Color(0xFF0D47A1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                leading: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
              ),
              
              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Typography showcase
                      _buildTypographySection(context),
                      
                      const SizedBox(height: 32),
                      
                      // Color palette showcase
                      _buildColorPaletteSection(context),
                      
                      const SizedBox(height: 32),
                      
                      // Gradient widgets showcase
                      _buildGradientWidgetsSection(context),
                      
                      const SizedBox(height: 32),
                      
                      // Interactive components showcase
                      _buildInteractiveComponentsSection(context),
                      
                      const SizedBox(height: 32),
                      
                      // Cards and containers showcase
                      _buildCardsSection(context),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: GradientBottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.palette),
            label: 'Theme',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildTypographySection(BuildContext context) {
    return GradientCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Typography Showcase',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: const Color(0xFFE65100),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Headlines - Large, bold fonts (28-32sp)
          Text(
            'Headline Large (32sp)',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Headline Medium (28sp)',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Headline Small (24sp)',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          
          const SizedBox(height: 16),
          
          // Body text - Medium-large fonts (18-20sp)
          Text(
            'Body Large (20sp) - This demonstrates the large body text with medium weight for excellent readability.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Body Medium (18sp) - This shows the medium body text that maintains readability while being slightly smaller.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Body Small (16sp) - This is the smallest body text, still maintaining the 16sp minimum for accessibility.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          
          const SizedBox(height: 16),
          
          // Labels with bold weights
          Text(
            'Label Large (18sp Bold)',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 4),
          Text(
            'Label Medium (16sp Bold)',
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Label Small (14sp Medium)',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }

  Widget _buildColorPaletteSection(BuildContext context) {
    return GradientCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Color Palette - Bold Dark Colors',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: const Color(0xFFE65100),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Primary colors
          _buildColorRow('Primary Dark', AppTheme.primaryDark),
          _buildColorRow('Primary Light', AppTheme.primaryLight),
          
          const SizedBox(height: 12),
          
          // Secondary colors
          _buildColorRow('Secondary Dark', AppTheme.secondaryDark),
          _buildColorRow('Secondary Light', AppTheme.secondaryLight),
          
          const SizedBox(height: 12),
          
          // Accent colors
          _buildColorRow('Accent Orange', AppTheme.accentOrange),
          _buildColorRow('Accent Orange Light', AppTheme.accentOrangeLight),
          
          const SizedBox(height: 12),
          
          // Surface colors
          _buildColorRow('Surface Dark', AppTheme.surfaceDark),
          _buildColorRow('Surface Light', AppTheme.surfaceLight),
        ],
      ),
    );
  }

  Widget _buildColorRow(String name, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  color.toString(),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientWidgetsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gradient Widgets',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: const Color(0xFFE65100),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Gradient buttons
        Row(
          children: [
            Expanded(
              child: GradientElevatedButton(
                onPressed: () {},
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A237E), Color(0xFF0D47A1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                child: const Text('Primary Button'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GradientElevatedButton(
                onPressed: () {},
                gradient: const LinearGradient(
                  colors: [Color(0xFF4A148C), Color(0xFF6A1B9A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                child: const Text('Secondary Button'),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Gradient circular button
        Center(
          child: GradientCircularButton(
            size: 100,
            gradient: const LinearGradient(
              colors: [Color(0xFFE65100), Color(0xFFFF6F00)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            onPressed: () {},
            child: const Icon(
              Icons.mic,
              size: 40,
              color: Colors.white,
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Gradient progress bar
        GradientCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Gradient Progress Bar (8dp thick)',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              const GradientProgressBar(
                value: 0.7,
                height: 8,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInteractiveComponentsSection(BuildContext context) {
    return GradientCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Interactive Components',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: const Color(0xFFE65100),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Switch with bold colors
          Row(
            children: [
              Expanded(
                child: Text(
                  'Switch with Bold Colors',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Switch(
                value: _switchValue,
                onChanged: (value) => setState(() => _switchValue = value),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Slider with gradient colors
          Text(
            'Slider with Gradient Colors (8dp track)',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Slider(
            value: _sliderValue,
            onChanged: (value) => setState(() => _sliderValue = value),
          ),
          
          const SizedBox(height: 20),
          
          // Text field with rounded corners
          const TextField(
            decoration: InputDecoration(
              labelText: 'Input with Rounded Corners (16dp)',
              hintText: 'Enter some text...',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cards & Containers',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: const Color(0xFFE65100),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Standard card with 16dp corners and 8dp elevation
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Standard Card',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This card demonstrates the standard Material Design 3 styling with 16dp rounded corners and 8dp elevation with dark shadows.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Gradient container
        GradientContainer(
          padding: const EdgeInsets.all(20),
          gradient: const LinearGradient(
            colors: [Color(0xFF1A237E), Color(0xFF0D47A1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Gradient Container',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This container showcases the gradient background with the same 16dp rounded corners and 8dp elevation.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Multiple gradient cards in a row
        Row(
          children: [
            Expanded(
              child: GradientCard(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4A148C), Color(0xFF6A1B9A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.palette,
                      size: 32,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Secondary',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GradientCard(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE65100), Color(0xFFFF6F00)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.star,
                      size: 32,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Accent',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}