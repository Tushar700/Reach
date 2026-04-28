String friendlySupabaseError(
  Object error, {
  String feature = 'This feature',
}) {
  final message = error.toString();
  final lower = message.toLowerCase();

  if (lower.contains('pgrst205') ||
      lower.contains('could not find the table') ||
      lower.contains('schema cache')) {
    return '$feature is not ready because your Supabase tables are missing. '
        'Run `supabase_schema.sql` in the Supabase SQL Editor, then try again.';
  }

  return message;
}
