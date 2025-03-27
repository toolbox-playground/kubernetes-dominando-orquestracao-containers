@RestController
@RequestMapping("/items")
public class ItemController {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @GetMapping
    public List<Item> getItems() {
        return jdbcTemplate.query("SELECT * FROM items", new BeanPropertyRowMapper<>(Item.class));
    }

    @PostMapping
    public ResponseEntity<?> addItem(@RequestBody Item item) {
        jdbcTemplate.update("INSERT INTO items (name) VALUES (?)", item.getName());
        return ResponseEntity.status(HttpStatus.CREATED).build();
    }
}
