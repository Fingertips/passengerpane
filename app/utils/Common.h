// Borrowed from Wil Shipley
// http://www.wilshipley.com/blog/2005/10/pimp-my-code-interlude-free-code.html
static inline BOOL IsEmpty(id thing) {
    return thing == nil
        || ([thing respondsToSelector:@selector(length)]
        && [(NSData *)thing length] == 0)
        || ([thing respondsToSelector:@selector(count)]
        && [(NSArray *)thing count] == 0);
}