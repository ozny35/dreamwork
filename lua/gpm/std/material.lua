--[[

    https://wiki.facepunch.com/gmod/Global.Material

    https://wiki.facepunch.com/gmod/Global.CreateMaterial

    https://wiki.facepunch.com/gmod/Global.DynamicMaterial



]]

do
    return
end

-- Material
do

    local string_dec2bin = string.dec2bin

    -- TODO: Think about material library

    local Material = game.Material
    if Material == nil then
        Material = _G.Material

        function std.Material( name, parameters )
            if parameters and parameters > 0 then
                parameters = string_dec2bin( parameters, true )

                local buffer = {}

                if string_byte( parameters, 1 ) == 0x31 then
                    buffer[ #buffer + 1 ] = "vertexlitgeneric"
                end

                if string_byte( parameters, 2 ) == 0x31 then
                    buffer[ #buffer + 1 ] = "nocull"
                end

                if string_byte( parameters, 3 ) == 0x31 then
                    buffer[ #buffer + 1 ] = "alphatest"
                end

                if string_byte( parameters, 4 ) == 0x31 then
                    buffer[ #buffer + 1 ] = "mips"
                end

                if string_byte( parameters, 5 ) == 0x31 then
                    buffer[ #buffer + 1 ] = "noclamp"
                end

                if string_byte( parameters, 6 ) == 0x31 then
                    buffer[ #buffer + 1 ] = "smooth"
                end

                if string_byte( parameters, 7 ) == 0x31 then
                    buffer[ #buffer + 1 ] = "ignorez"
                end

                return Material( name, table_concat( buffer, " " ) )
            end

            return Material( name )
        end
    else

        --- Either returns the material with the given name, or loads the material interpreting the first argument as the path.
        ---
        --- `.png`, `.jpg` and other image formats.
        ---
        ---
        --- This function is capable to loading .png or .jpg images, generating a texture and material for them on the fly.
        ---
        ---
        --- `PNG`, `JPEG`, `GIF`, and `TGA` files will work, but only if they have the `.png` or `.jpg` file extensions (even if the actual image format doesn't match the file extension)
        ---@param name string The material name or path relative to the `materials/` folder.
        --- Paths outside the `materials/` folder like `data/MyImage.jpg` or `maps/thumb/gm_construct.png` will also work for when generating materials.
        --- To retrieve a Lua material created with `CreateMaterial`, just prepend a `!` to the material name.
        ---@param parameters? number A bit flag of material parameters.
        ---@return IMaterial
        function std.Material( name, parameters )
            if parameters and parameters > 0 then
                ---@diagnostic disable-next-line: return-type-mismatch
                return Material( name, string_dec2bin( parameters, true ) )
            end

            ---@diagnostic disable-next-line: return-type-mismatch
            return Material( name )
        end

    end

end
