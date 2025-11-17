// Test the enhanced getFlowOptions method
List<Map<String, Object>> options = FS_DiffService.getFlowOptions();
System.debug('Flow Options Count: ' + options.size());

for (Map<String, Object> option : options) {
    System.debug('Flow Option: ' + option);
}