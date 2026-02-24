import { View, Text, TouchableOpacity, ScrollView, StyleSheet } from 'react-native';
import { Link } from 'expo-router';

const games = [
  { id: 'emotion-explorer', title: 'Emotion Explorer', emoji: '😊', color: '#FFD93D' },
  { id: 'focus-forest', title: 'Focus Forest', emoji: '🌳', color: '#6BCB77' },
  { id: 'social-stories', title: 'Social Stories', emoji: '👫', color: '#4D96FF' },
  { id: 'sensory-space', title: 'Sensory Space', emoji: '🌈', color: '#FF6B6B' },
  { id: 'task-tower', title: 'Task Tower', emoji: '🏗️', color: '#C084FC' },
  { id: 'word-world', title: 'Word World', emoji: '📚', color: '#F97316' },
];

export default function Home() {
  return (
    <ScrollView style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.greeting}>Hi there! 👋</Text>
        <Text style={styles.subtitle}>Ready to play and learn?</Text>
      </View>

      <View style={styles.grid}>
        {games.map((game) => (
          <Link key={game.id} href={`/game/${game.id}`} asChild>
            <TouchableOpacity style={[styles.card, { backgroundColor: game.color }]}>
              <Text style={styles.emoji}>{game.emoji}</Text>
              <Text style={styles.cardTitle}>{game.title}</Text>
            </TouchableOpacity>
          </Link>
        ))}
      </View>

      <View style={styles.nav}>
        <Link href="/progress" asChild>
          <TouchableOpacity style={styles.navButton}>
            <Text style={styles.navText}>📊 Progress</Text>
          </TouchableOpacity>
        </Link>
        <Link href="/settings" asChild>
          <TouchableOpacity style={styles.navButton}>
            <Text style={styles.navText}>⚙️ Settings</Text>
          </TouchableOpacity>
        </Link>
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#F0F7FF' },
  header: { padding: 24, paddingTop: 16 },
  greeting: { fontSize: 28, fontWeight: 'bold', color: '#1a1a1a' },
  subtitle: { fontSize: 16, color: '#666', marginTop: 4 },
  grid: { flexDirection: 'row', flexWrap: 'wrap', paddingHorizontal: 16, gap: 12 },
  card: {
    width: '47%',
    borderRadius: 16,
    padding: 20,
    alignItems: 'center',
    justifyContent: 'center',
    minHeight: 140,
  },
  emoji: { fontSize: 40, marginBottom: 8 },
  cardTitle: { fontSize: 14, fontWeight: '600', color: '#fff', textAlign: 'center' },
  nav: { flexDirection: 'row', justifyContent: 'center', gap: 16, padding: 24 },
  navButton: {
    backgroundColor: '#fff',
    paddingHorizontal: 24,
    paddingVertical: 12,
    borderRadius: 12,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.1,
    shadowRadius: 2,
    elevation: 2,
  },
  navText: { fontSize: 16, fontWeight: '500' },
});
