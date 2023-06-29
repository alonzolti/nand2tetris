def another_function():
    x = 15
    inner_function()
    def outer_function():
        x = 10

        def inner_function():
            y = x + 5  # Accessing x from the outer scope dynamically
            print(y)

        inner_function()


another_function()