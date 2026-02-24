import { Stack } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';

const queryClient = new QueryClient();

export default function RootLayout() {
  return (
    <QueryClientProvider client={queryClient}>
      <Stack
        screenOptions={{
          headerStyle: { backgroundColor: '#0c8de7' },
          headerTintColor: '#fff',
          headerTitleStyle: { fontWeight: 'bold' },
        }}
      >
        <Stack.Screen name="index" options={{ title: 'KidNeuro' }} />
        <Stack.Screen name="game/[id]" options={{ title: 'Game', headerShown: false }} />
        <Stack.Screen name="progress/index" options={{ title: 'Progress' }} />
        <Stack.Screen name="profile/index" options={{ title: 'Profile' }} />
        <Stack.Screen name="settings/index" options={{ title: 'Settings' }} />
      </Stack>
      <StatusBar style="light" />
    </QueryClientProvider>
  );
}
