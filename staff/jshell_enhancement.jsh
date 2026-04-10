import java.util.Arrays;

/**
 * similar to python print func
 * @param args args to print, separated by space
 */
void print(Object... args) {
    for (int i = 0; i < args.length; i++) {
        if (i > 0) System.out.print(" ");
        System.out.print(formatValue(args[i]));
    }
    System.out.println();
}

String formatValue(Object obj) {
    if (obj == null) {
        return "null";
    }
    if (obj.getClass().isArray()) {
        return formatArray(obj);
    }
    if (obj instanceof String) {
        return (String) obj;
    }
    return obj.toString();
}

String formatArray(Object arr) {
    Class<?> compType = arr.getClass().getComponentType();
    if (compType == byte.class) {
        return Arrays.toString((byte[]) arr);
    } else if (compType == short.class) {
        return Arrays.toString((short[]) arr);
    } else if (compType == int.class) {
        return Arrays.toString((int[]) arr);
    } else if (compType == long.class) {
        return Arrays.toString((long[]) arr);
    } else if (compType == float.class) {
        return Arrays.toString((float[]) arr);
    } else if (compType == double.class) {
        return Arrays.toString((double[]) arr);
    } else if (compType == char.class) {
        return Arrays.toString((char[]) arr);
    } else if (compType == boolean.class) {
        return Arrays.toString((boolean[]) arr);
    } else {
        // Object arrays
        Object[] objArr = (Object[]) arr;
        StringBuilder sb = new StringBuilder("[");
        for (int i = 0; i < objArr.length; i++) {
            if (i > 0) sb.append(", ");
            sb.append(formatValue(objArr[i]));
        }
        sb.append("]");
        return sb.toString();
    }
}

void bytes(String s) {
    byte[] bytes = s.getBytes();
    for (byte b : bytes) {
        System.out.print(Integer.toHexString((b & 0xFF)) + " ");
    }
    System.out.println();
}

print("\033[2mQfig jshell enhancement enabled\033[0m");

