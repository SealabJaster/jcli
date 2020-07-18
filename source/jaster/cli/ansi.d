/// Utilities to create ANSI coloured text.
module jaster.cli.ansi;

import std.traits : EnumMembers;
import std.typecons : Flag;

alias IsBgColour = Flag!"isBackgroundAnsi";

/++
 + Defines what type of colour an `AnsiColour` stores.
 + ++/
enum AnsiColourType
{
    /// Default, failsafe.
    none,

    /// 4-bit colours.
    fourBit,

    /// 8-bit colours.
    eightBit,

    /// 24-bit colours.
    rgb
}

/++
 + An enumeration of standard 4-bit colours.
 +
 + These colours will have the widest support between platforms.
 + ++/
enum Ansi4BitColour
{
    // To get Background code, just add 10
    black           = 30,
    red             = 31,
    green           = 32,
    /// On Powershell, this is displayed as a very white colour.
    yellow          = 33,
    blue            = 34,
    magenta         = 35,
    cyan            = 36,
    /// More gray than true white, use `BrightWhite` for true white.
    white           = 37,
    /// Grayer than `White`.
    brightBlack     = 90,
    brightRed       = 91,
    brightGreen     = 92,
    brightYellow    = 93,
    brightBlue      = 94,
    brightMagenta   = 95,
    brightCyan      = 96,
    brightWhite     = 97
}

private union AnsiColourUnion
{
    Ansi4BitColour fourBit;
    ubyte          eightBit;
    AnsiRgbColour  rgb;
}

/// A very simple RGB struct, used to store an RGB value.
struct AnsiRgbColour
{
    /// The red component.
    ubyte r;
    
    /// The green component.
    ubyte g;

    /// The blue component.
    ubyte b;
}

/++
 + Contains either a 4-bit, 8-bit, or 24-bit colour, which can then be turned into
 + an its ANSI form (not a valid command, just the actual values needed to form the final command).
 + ++/
@safe
struct AnsiColour
{
    private 
    {
        AnsiColourUnion _value;
        AnsiColourType  _type;
        IsBgColour      _isBg;

        this(IsBgColour isBg)
        {
            this._isBg = isBg;
        }
    }

    /// A variant of `.init` that is used for background colours.
    static immutable bgInit = AnsiColour(IsBgColour.yes);

    /// Ctor for an `AnsiColourType.fourBit`.
    @nogc
    this(Ansi4BitColour fourBit, IsBgColour isBg = IsBgColour.no) nothrow pure
    {
        this._value.fourBit = fourBit;
        this._type          = AnsiColourType.fourBit;
        this._isBg          = isBg;
    }

    /// Ctor for an `AnsiColourType.eightBit`
    @nogc
    this(ubyte eightBit, IsBgColour isBg = IsBgColour.no) nothrow pure
    {
        this._value.eightBit = eightBit;
        this._type           = AnsiColourType.eightBit;
        this._isBg           = isBg;
    }

    /// Ctor for an `AnsiColourType.rgb`.
    @nogc
    this(ubyte r, ubyte g, ubyte b, IsBgColour isBg = IsBgColour.no) nothrow pure
    {        
        this._value.rgb = AnsiRgbColour(r, g, b);
        this._type      = AnsiColourType.eightBit;
        this._isBg      = isBg;
    }

    /// ditto
    @nogc
    this(AnsiRgbColour rgb, IsBgColour isBg = IsBgColour.no) nothrow pure
    {
        this(rgb.r, rgb.g, rgb.b, isBg);
    }

    /++
     + Notes:
     +  To create a valid ANSI command from these values, prefix it with "\033[" and suffix it with "m", then place your text after it.
     +
     + Returns:
     +  This `AnsiColour` as an incomplete ANSI command.
     + ++/
    string toString() const pure
    {
        import std.format : format;

        final switch(this._type) with(AnsiColourType)
        {
            case none: return null;
            case fourBit:
                auto value = cast(int)this._value.fourBit;
                return "%s".format(this._isBg ? value + 10 : value);

            case eightBit:
                auto marker = (this._isBg) ? "48" : "38";
                auto value  = this._value.eightBit;
                return "%s;5;%s".format(marker, value);

            case rgb:
                auto marker = (this._isBg) ? "48" : "38";
                auto value  = this._value.rgb;
                return "%s;2;%s;%s;%s".format(marker, value.r, value.g, value.b);
        }
    }

    @safe @nogc nothrow pure:
    
    /// Returns: The `AnsiColourType` of this `AnsiColour`.
    @property
    AnsiColourType type() const
    {
        return this._type;
    }

    /// Returns: Whether this `AnsiColour` is for a background or not (it affects the output!).
    @property
    IsBgColour isBg() const
    {
        return this._isBg;
    }

    /// ditto
    @property
    void isBg(IsBgColour bg)
    {
        this._isBg = bg;
    }

    /// ditto
    @property
    void isBg(bool bg)
    {
        this._isBg = cast(IsBgColour)bg;
    }

    /++
     + Assertions:
     +  This colour's type must be `AnsiColourType.fourBit`
     +
     + Returns:
     +  This `AnsiColour` as an `Ansi4BitColour`.
     + ++/
    @property
    Ansi4BitColour asFourBit()
    {
        assert(this.type == AnsiColourType.fourBit);
        return this._value.fourBit;
    }

    /++
     + Assertions:
     +  This colour's type must be `AnsiColourType.eightBit`
     +
     + Returns:
     +  This `AnsiColour` as a `ubyte`.
     + ++/
    @property
    ubyte asEightBit()
    {
        assert(this.type == AnsiColourType.eightBit);
        return this._value.eightBit;
    }

    /++
     + Assertions:
     +  This colour's type must be `AnsiColourType.rgb`
     +
     + Returns:
     +  This `AnsiColour` as an `AnsiRgbColour`.
     + ++/
    @property
    AnsiRgbColour asRgb()
    {
        assert(this.type == AnsiColourType.rgb);
        return this._value.rgb;
    }
}

enum AnsiTextFlags
{
    none      = 0,
    bold      = 1 << 0,
    dim       = 1 << 1,
    italic    = 1 << 2,
    underline = 1 << 3,
    slowBlink = 1 << 4,
    fastBlink = 1 << 5,
    invert    = 1 << 6,
    strike    = 1 << 7
}

private immutable FLAG_COUNT = EnumMembers!AnsiTextFlags.length - 1; // - 1 to ignore the `none` option
private immutable FLAG_AS_ANSI_CODE_MAP = 
[
    // Index correlates to the flag's position in the bitmap.
    // So bold would be index 0.
    // Strike would be index 7, etc.
    
    "1", // 0
    "2", // 1
    "3", // 2
    "4", // 3
    "5", // 4
    "6", // 5
    "7", // 6
    "9"  // 7
];
static assert(FLAG_AS_ANSI_CODE_MAP.length == FLAG_COUNT);

/// An alias for a string[] containing exactly enough elements for the following ANSI strings:
///
/// * [0]    = Foreground ANSI code.
/// * [1]    = Background ANSI code.
/// * [2..n] = The code for any `AnsiTextFlags` that are set.
alias AnsiComponents = string[2 + FLAG_COUNT]; // fg + bg + all supported flags.

/++
 + Populates an `AnsiComponents` with all the strings required to construct a full ANSI command string.
 +
 + Params:
 +  components = The `AnsiComponents` to populate. $(B All values will be set to null before hand).
 +  fg         = The `AnsiColour` representing the foreground.
 +  bg         = The `AnsiColour` representing the background.
 +  flags      = The `AnsiTextFlags` to apply.
 +
 + Returns:
 +  How many components in total are active.
 +
 + See_Also:
 +  `createAnsiCommandString` to create an ANSI command string from an `AnsiComponents`.
 + ++/
@safe
size_t populateActiveAnsiComponents(ref scope AnsiComponents components, AnsiColour fg, AnsiColour bg, AnsiTextFlags flags) pure
{
    size_t componentIndex;
    components[] = null;

    if(fg.type != AnsiColourType.none)
        components[componentIndex++] = fg.toString();

    if(bg.type != AnsiColourType.none)
        components[componentIndex++] = bg.toString();

    foreach(i; 0..FLAG_COUNT)
    {
        if((flags & (1 << i)) > 0)
            components[componentIndex++] = FLAG_AS_ANSI_CODE_MAP[i];
    }

    return componentIndex;
}

/++
 + Creates an ANSI command string using the given active `components`.
 +
 + Params:
 +  components = An `AnsiComponents` that has been populated with flags, ideally from `populateActiveAnsiComponents`.
 +
 + Returns:
 +  All of the component strings inside of `components`, formatted as a valid ANSI command string.
 + ++/
@safe
string createAnsiCommandString(ref scope AnsiComponents components) pure
{
    import std.algorithm : joiner, filter;
    import std.format    : format;

    return "\033[%sm".format(components[].filter!(s => s !is null).joiner(";")); 
}

/// Contains a single character, with ANSI styling.
@safe
struct AnsiChar 
{
    import jaster.cli.ansi : AnsiColour, AnsiTextFlags, IsBgColour;

    /// foreground
    AnsiColour    fg;
    /// background by reference
    AnsiColour    bgRef;
    /// flags
    AnsiTextFlags flags;
    /// character
    char          value;

    @nogc nothrow pure:

    /++
     + Returns:
     +  Whether this character needs an ANSI control code or not.
     + ++/
    @property
    bool usesAnsi() const
    {
        return this.fg    != AnsiColour.init
            || (this.bg   != AnsiColour.init && this.bg != AnsiColour.bgInit)
            || this.flags != AnsiTextFlags.none;
    }

    /// Set the background (automatically sets `value.isBg` to `yes`)
    @property
    void bg(AnsiColour value)
    {
        value.isBg = IsBgColour.yes;
        this.bgRef = value;
    }

    /// Get the background.
    @property
    AnsiColour bg() const { return this.bgRef; }
}

/++
 + A struct used to compose together a piece of ANSI text.
 +
 + Notes:
 +  A reset command (`\033[0m`) is automatically appended, so you don't have to worry about that.
 +
 +  This struct is simply a wrapper around `AnsiColour`, `AnsiTextFlags` types, and the `populateActiveAnsiComponents` and
 +  `createAnsiCommandString` functions.
 +
 + Usage:
 +  This struct uses the Fluent Builder pattern, so you can easily string together its
 +  various functions when creating your text.
 +
 +  Set the background colour with `AnsiText.bg`
 +
 +  Set the foreground/text colour with `AnsiText.fg`
 +
 +  AnsiText uses `toString` to provide the final output, making it easily used with the likes of `writeln` and `format`.
 + ++/
@safe
struct AnsiText
{
    import std.format : format;

    /// The ANSI command to reset all styling.
    public static const RESET_COMMAND = "\033[0m";

    @nogc
    private nothrow pure
    {
        string        _cachedText;
        const(char)[] _text;
        AnsiColour    _fg;
        AnsiColour    _bg;
        AnsiTextFlags _flags;

        ref AnsiText setColour(T)(ref AnsiColour colour, T value) return
        {
            colour = AnsiColour(value);
            this._cachedText = null;
            return this;
        }

        ref AnsiText setColour4(ref AnsiColour colour, Ansi4BitColour value) return
        {
            return this.setColour(colour, Ansi4BitColour(value));
        }

        ref AnsiText setColour8(ref AnsiColour colour, ubyte value) return
        {
            return this.setColour(colour, value);
        }

        ref AnsiText setColourRgb(ref AnsiColour colour, ubyte r, ubyte g, ubyte b) return
        {
            return this.setColour(colour, AnsiRgbColour(r, g, b));
        }

        ref AnsiText setFlag(AnsiTextFlags flag, bool isSet) return
        {
            if(isSet)
                this._flags |= flag;
            else
                this._flags &= ~flag;

            this._cachedText = null;
            return this;
        }
    }

    ///
    @safe @nogc
    this(const(char)[] text) nothrow pure
    {
        this._text = text;
        this._bg.isBg = true;
    }

    /++
     + Notes:
     +  If no ANSI escape codes are used, then this function will simply return a `.idup` of the
     +  text provided to this struct's constructor.
     +
     + Returns:
     +  The ANSI escape-coded text.
     + ++/
    @safe
    string toString() pure
    {
        if(this._bg.type == AnsiColourType.none 
        && this._fg.type == AnsiColourType.none
        && this._flags   == AnsiTextFlags.none)
            this._cachedText = this._text.idup;

        if(this._cachedText !is null)
            return this._cachedText;

        // Find all 'components' that have been enabled
        AnsiComponents components;
        components.populateActiveAnsiComponents(this._fg, this._bg, this._flags);

        // Then join them together.
        this._cachedText = "%s%s%s".format(
            components.createAnsiCommandString(), 
            this._text,
            AnsiText.RESET_COMMAND
        ); 
        return this._cachedText;
    }

    @safe @nogc nothrow pure:

    /// Sets the foreground/background as a 4-bit colour. Widest supported option.
    ref AnsiText fg(Ansi4BitColour fourBit) return    { return this.setColour4  (this._fg, fourBit);  }
    /// ditto
    ref AnsiText bg(Ansi4BitColour fourBit) return    { return this.setColour4  (this._bg, fourBit);  }

    /// Sets the foreground/background as an 8-bit colour. Please see this image for reference: https://i.stack.imgur.com/KTSQa.png
    ref AnsiText fg(ubyte eightBit) return            { return this.setColour8  (this._fg, eightBit); }
    /// ditto
    ref AnsiText bg(ubyte eightBit) return            { return this.setColour8  (this._bg, eightBit); }

    /// Sets the forground/background as an RGB colour.
    ref AnsiText fg(ubyte r, ubyte g, ubyte b) return { return this.setColourRgb(this._fg, r, g, b);  }
    /// ditto
    ref AnsiText bg(ubyte r, ubyte g, ubyte b) return { return this.setColourRgb(this._bg, r, g, b);  }

    /// Sets whether the text is bold.
    ref AnsiText bold     (bool isSet = true) return { return this.setFlag(AnsiTextFlags.bold,      isSet); }
    /// Sets whether the text is dimmed (opposite of bold).
    ref AnsiText dim      (bool isSet = true) return { return this.setFlag(AnsiTextFlags.dim,       isSet); }
    /// Sets whether the text should be displayed in italics.
    ref AnsiText italic   (bool isSet = true) return { return this.setFlag(AnsiTextFlags.italic,    isSet); }
    /// Sets whether the text has an underline.
    ref AnsiText underline(bool isSet = true) return { return this.setFlag(AnsiTextFlags.underline, isSet); }
    /// Sets whether the text should blink slowly.
    ref AnsiText slowBlink(bool isSet = true) return { return this.setFlag(AnsiTextFlags.slowBlink, isSet); }
    /// Sets whether the text should blink rapidly.
    ref AnsiText fastBlink(bool isSet = true) return { return this.setFlag(AnsiTextFlags.fastBlink, isSet); }
    /// Sets whether the text should have its fg and bg colours inverted.
    ref AnsiText invert   (bool isSet = true) return { return this.setFlag(AnsiTextFlags.invert,    isSet); }
    /// Sets whether the text should have a strike through it.
    ref AnsiText strike   (bool isSet = true) return { return this.setFlag(AnsiTextFlags.strike,    isSet); }

    /// Sets the `AnsiTextFlags` for this piece of text.
    ref AnsiText setFlags(AnsiTextFlags flags) return 
    { 
        this._flags = flags; 
        return this; 
    }

    /// Gets the `AnsiTextFlags` for this piece of text.
    @property
    AnsiTextFlags flags() const
    {
        return this._flags;
    }

    /// Gets the `AnsiColour` used as the foreground (text colour).
    //@property
    AnsiColour fg() const
    {
        return this._fg;
    }

    /// Gets the `AnsiColour` used as the background.
    //@property
    AnsiColour bg() const
    {
        return this._bg;
    }

    /// Returns: The raw text of this `AnsiText`.
    @property
    const(char[]) rawText() const
    {
        return this._text;
    }
}

/++
 + A helper UFCS function used to fluently convert any piece of text into an `AnsiText`.
 + ++/
@safe @nogc
AnsiText ansi(const char[] text) nothrow pure
{
    return AnsiText(text);
}
///
@safe
unittest
{
    assert("Hello".ansi.toString() == "Hello");
    assert("Hello".ansi.fg(Ansi4BitColour.black).toString() == "\033[30mHello\033[0m");
    assert("Hello".ansi.bold.strike.bold(false).italic.toString() == "\033[3;9mHello\033[0m");
}

/// On windows - enable ANSI support.
version(Windows)
{
    static this()
    {
        import core.sys.windows.windows : HANDLE, DWORD, GetStdHandle, STD_OUTPUT_HANDLE, GetConsoleMode, SetConsoleMode, ENABLE_VIRTUAL_TERMINAL_PROCESSING;

        HANDLE stdOut = GetStdHandle(STD_OUTPUT_HANDLE);
        DWORD mode = 0;

        GetConsoleMode(stdOut, &mode);
        mode |= ENABLE_VIRTUAL_TERMINAL_PROCESSING;
        SetConsoleMode(stdOut, mode);
    }
}