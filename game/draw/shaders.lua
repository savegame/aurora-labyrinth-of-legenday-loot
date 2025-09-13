local SHADERS = {  }
SHADERS.INVERT = graphics.newShader([[
    vec4 effect(vec4 color, Image texture, vec2 textureCoords, vec2 screenCoords){
        vec4 textureColor = Texel(texture, textureCoords);
        vec4 newColor;
        newColor[0] = 1.0 - textureColor[0];
        newColor[1] = 1.0 - textureColor[1];
        newColor[2] = 1.0 - textureColor[2];
        newColor[3] = textureColor[3];
        return newColor * color;
    }
]])
SHADERS.DESATURATE = graphics.newShader([[
    vec4 effect(vec4 color, Image texture, vec2 textureCoords, vec2 screenCoords){
        vec4 textureColor = Texel(texture, textureCoords);
        vec4 newColor;
        number minValue, maxValue, value;
        minValue = min(textureColor[0], textureColor[1]);
        minValue = min(minValue, textureColor[2]);
        maxValue = max(textureColor[0], textureColor[1]);
        maxValue = max(maxValue, textureColor[2]);
        value = (minValue + maxValue)/2.0;
        newColor[0] = value;
        newColor[1] = value;
        newColor[2] = value;
        newColor[3] = textureColor[3];
        return newColor * color;
    }
]])
SHADERS.FILTER_OUTLINE = graphics.newShader([[
    vec4 effect(vec4 color, Image texture, vec2 textureCoords, vec2 screenCoords)
    {
        vec4 textureColor = Texel(texture, textureCoords);
        if(textureColor.r < 0.15 && textureColor.g < 0.15 && textureColor.b < 0.15 && textureColor.a > 0.95){
            return vec4(0, 0, 0, 0);
        } else {
            return textureColor * color;
        }
    }
]])
SHADERS.OUTLINE_AS_COLOR = graphics.newShader([[
    vec4 effect(vec4 color, Image texture, vec2 textureCoords, vec2 screenCoords)
    {
        vec4 textureColor = Texel(texture, textureCoords);
        if(textureColor.r < 0.15 && textureColor.g < 0.15 && textureColor.b < 0.15 && textureColor.a > 0.95 && textureColor.r > 0.1 && textureColor.g > 0.1 && textureColor.b > 0.1){
            return color;
        } else {
            return vec4(0, 0, 0, 0);
        }
    }
]])
SHADERS.SILHOUETTE = graphics.newShader([[
    vec4 effect(vec4 color, Image texture, vec2 textureCoords, vec2 screenCoords)
    {
        vec4 textureColor = Texel(texture, textureCoords);
        return vec4(color[0], color[1], color[2], color[3]*textureColor[3]);
    }
]])
SHADERS.SILHOUETTE_NO_OUTLINE = graphics.newShader([[
    vec4 effect(vec4 color, Image texture, vec2 textureCoords, vec2 screenCoords)
    {
        vec4 textureColor = Texel(texture, textureCoords);
        if(textureColor.r < 0.15 && textureColor.g < 0.15 && textureColor.b < 0.15){
            return vec4(0, 0, 0, 0);
        } else {
            return vec4(color[0], color[1], color[2], color[3]*textureColor[3]);
        }
    }
]])
return SHADERS

