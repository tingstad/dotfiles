console.log(
    JSON.stringify(
        JSON.parse(require('fs').readFileSync(0, 'utf-8')),
        null,
        (args =>
            (argsLength =>
                argsLength > 1
                    ? (arg =>
                        (num => Number.isInteger(num) ? num : arg
                        )(Number(arg))
                      )(args[argsLength - 1])
                    : 4
            )(args.length)
        )(process.argv)
    )
);

