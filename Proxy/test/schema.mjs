// A deliberately small JSON Schema checker covering only the keywords the contract files use.
// The alternative — pulling in a validator — would add a dependency to a Worker whose entire
// point is a minimal attack surface, for a job this size.
export function validate(schema, value, path = "$") {
  const errors = [];

  const types = schema.type ? [schema.type].flat() : null;
  if (types && !types.some((type) => matchesType(type, value))) {
    errors.push(`${path}: expected ${types.join(" or ")}, got ${describe(value)}`);
    return errors;
  }

  if (schema.enum && !schema.enum.includes(value)) {
    errors.push(`${path}: ${JSON.stringify(value)} is not one of ${schema.enum.join(", ")}`);
  }

  if (typeof value === "string") {
    if (schema.minLength != null && value.length < schema.minLength) {
      errors.push(`${path}: shorter than ${schema.minLength}`);
    }
  }

  if (typeof value === "number") {
    if (schema.minimum != null && value < schema.minimum) errors.push(`${path}: below ${schema.minimum}`);
    if (schema.maximum != null && value > schema.maximum) errors.push(`${path}: above ${schema.maximum}`);
    if (types?.includes("integer") && !Number.isInteger(value)) errors.push(`${path}: not an integer`);
  }

  if (Array.isArray(value)) {
    if (schema.minItems != null && value.length < schema.minItems) errors.push(`${path}: fewer than ${schema.minItems} items`);
    if (schema.items) {
      value.forEach((item, index) => errors.push(...validate(schema.items, item, `${path}[${index}]`)));
    }
  }

  if (isPlainObject(value)) {
    for (const key of schema.required ?? []) {
      if (!(key in value)) errors.push(`${path}: missing required key "${key}"`);
    }
    if (schema.additionalProperties === false) {
      for (const key of Object.keys(value)) {
        if (!(key in (schema.properties ?? {}))) errors.push(`${path}: unexpected key "${key}"`);
      }
    }
    for (const [key, subSchema] of Object.entries(schema.properties ?? {})) {
      if (key in value) errors.push(...validate(subSchema, value[key], `${path}.${key}`));
    }
  }

  return errors;
}

function matchesType(type, value) {
  if (type === "null") return value === null;
  if (type === "array") return Array.isArray(value);
  if (type === "object") return isPlainObject(value);
  if (type === "integer") return typeof value === "number";
  return typeof value === type;
}

const isPlainObject = (value) => typeof value === "object" && value !== null && !Array.isArray(value);

const describe = (value) => (value === null ? "null" : Array.isArray(value) ? "array" : typeof value);
