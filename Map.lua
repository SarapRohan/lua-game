--[[
    Contains tile data and necessary code for rendering a tile map to the
    screen.
]]

require 'Util'

-- object-oriented boilerplate; establish Map's "prototype"
Map = {}
Map.__index = Map

TILE_BRICK = 1
TILE_EMPTY = 29
TILE_STAIR = 14

-- cloud tiles
CLOUD_TOP_LEFT = 661
CLOUD_TOP_MIDDLE = 662
CLOUD_TOP_RIGHT = 663
CLOUD_BOTTOM_LEFT = 694
CLOUD_BOTTOM_MIDDLE = 695
CLOUD_BOTTOM_RIGHT = 696

-- bush tiles
BUSH_LEFT = 309
BUSH_MIDDLE = 310
BUSH_RIGHT = 311

-- a speed to multiply delta time to scroll map; smooth value
local scrollSpeed = 300

-- constructor for our map object
function Map:create()
    local this = {
        -- our texture containing all sprites
        spritesheet = love.graphics.newImage('graphics/tiles.png'),
        tileWidth = 16,
        tileHeight = 16,
        mapWidth = 130,
        mapHeight = 28,
        tiles = {},

        -- applies positive y influence on anything affected
        gravity = 15,

        -- camera offsets
        camY = -3,
        camX = 0
    }

    -- associate player with map
    this.player = Player:create(this)

    -- generate a quad (individual frame/sprite) for each tile
    this.tileSprites = generateQuads(this.spritesheet, 16, 16)

    -- cache width and height of map in pixels
    this.mapWidthPixels = this.mapWidth * this.tileWidth
    this.mapHeightPixels = this.mapHeight * this.tileHeight

    -- sprite batch for efficient tile rendering
    this.spriteBatch = love.graphics.newSpriteBatch(this.spritesheet, this.mapWidth *
        this.mapHeight)

    -- more OO boilerplate so we have access to class functions
    setmetatable(this, self)

    -- first, fill map with empty tiles
    for y = 1, this.mapHeight do
        for x = 1, this.mapWidth do
            this:setTile(x, y, TILE_EMPTY)
        end
    end

    local x = 3
    local cloudStart = 4

    this:setTile(x, cloudStart, CLOUD_TOP_LEFT)
    this:setTile(x, cloudStart + 1, CLOUD_BOTTOM_LEFT)
    this:setTile(x + 1, cloudStart, CLOUD_TOP_MIDDLE)
    this:setTile(x + 1, cloudStart + 1, CLOUD_BOTTOM_MIDDLE)
    this:setTile(x + 2, cloudStart, CLOUD_TOP_RIGHT)
    this:setTile(x + 2, cloudStart + 1, CLOUD_BOTTOM_RIGHT)

    local bushLevel = this.mapHeight / 2
    local x = 2
    local stairs_end = 105
    -- place bush component and then column of bricks
    this:setTile(x, bushLevel, BUSH_LEFT)
    x = x + 1
    this:setTile(x, bushLevel, BUSH_MIDDLE)
    x = x + 1

    this:setTile(x, bushLevel, BUSH_RIGHT)
    x = x + 1

    -- fill bottom half of map with tiles
    for y = bushLevel + 1, this.mapHeight do
        for x = 1, this.mapWidth do
            this:setTile(x, y, TILE_BRICK)
        end
    end

    y = bushLevel
    local stair = 20

    while y > bushLevel - 31 do
        for x = stair, stairs_end do
            this:setTile(x, y, TILE_STAIR)
        end
        y = y - 1
        stair = stair + 3
    end

    -- create sprite batch from tile quads
    for y = 1, this.mapHeight do
        for x = 1, this.mapWidth do
            this.spriteBatch:add(this.tileSprites[this:getTile(x, y)],
                (x - 1) * this.tileWidth, (y - 1) * this.tileHeight)
        end
    end

    return this
end

-- return whether a given tile is collidable
function Map:collides(tile)
    -- define our collidable tiles
    local collidables = {
        TILE_BRICK, TILE_STAIR
    }

    -- iterate and return true if our tile type matches
    for _, v in ipairs(collidables) do
        if tile == v then
            return true
        end
    end

    return false
end

-- function to update camera offset based on player coordinates
function Map:update(dt)
    self.player:update(dt)

    -- keep camera's X coordinate following the player, preventing camera from
    -- scrolling past 0 to the left and the map's width
    self.camX = math.max(0, math.min(self.player.x - virtualWidth / 2,
        math.min(self.mapWidthPixels - virtualWidth, self.player.x)))
end

-- gets the tile type at a given pixel coordinate
function Map:tileAt(x, y)
    return self:getTile(math.floor(x / self.tileWidth) + 1, math.floor(y / self.tileHeight) + 1)
end

-- returns an integer value for the tile at a given x-y coordinate
function Map:getTile(x, y)
    return self.tiles[(y - 1) * self.mapWidth + x]
end

-- sets a tile at a given x-y coordinate to an integer value
function Map:setTile(x, y, tile)
    self.tiles[(y - 1) * self.mapWidth + x] = tile
end

-- renders our map to the screen, to be called by main's render
function Map:render()
    -- replace tile-by-tile rendering with spriteBatch draw call
    love.graphics.draw(self.spriteBatch)
    self.player:render()
end
