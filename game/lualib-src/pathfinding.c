#include <lua.h>
#include <lauxlib.h>
#include <stdint.h>
#include <string.h>
#include <stdlib.h>
#include <assert.h>

#define SEARCH_DEPTH 1024
#define BLOCK_WEIGHT 255

struct map {
	int width;
	int height;
	uint8_t m[0];
};

struct pathnode {
	int x;
	int y;
	int camefrom;
	int gscore;
	int fscore;
};

struct path {
	int depth;
	int *set;
	struct pathnode *n;
};

struct route_coord {
	int x;
	int y;
};

struct route_queue {
	int head;
	int tail;
	int n;
	struct route_coord q[0];
};

static inline int
map_set(struct map *m, int x, int y, int w) {
	int v = m->m[y * m->width + x];
	m->m[y * m->width + x] = w;
	return v;
}

static inline int
map_get(struct map *m, int x, int y) {
	return m->m[y * m->width + x];
}

static void
addbuilding(lua_State *L, struct map *m, int x, int y, int size) {
	//x = x * 2 + 1;
	//y = y * 2 + 1;
	//size = size * 2 - 1;
	if (x < 0 || x + size >= m->width ||
		y < 0 || y + size >= m->height) {
		luaL_error(L, "building (%d,%d,%d) is out of map", (x-2)/2,(y-2)/2,(size+1)/2);
	}
	int i,j;
	for (i=0;i<size;i++) {
		for (j=0;j<size;j++) {
			if (map_set(m, j + x, i + y, BLOCK_WEIGHT) != 0) {
				luaL_error(L, "Can't add building (%d,%d,%d)", (x-2)/2,(y-2)/2,(size+1)/2);
			}
		}
	}
}

static int
getfield(lua_State *L, int index, const char *f) {
	if (lua_getfield(L, -1, f) != LUA_TNUMBER) {
		return luaL_error(L, "invalid [%d].%s", index, f);
	}
	int v = lua_tointeger(L, -1);
	lua_pop(L, 1);
	return v;
}

static void
addwall(lua_State *L, struct map *m, int line, const char *wall, size_t width) {
	int y = line * 2 + 1;
	int i;
	if (y >= m->height - 1) {
		luaL_error(L, "add wall (y = %d) fail", y);
	}
	for (i=0;i<width;i++) {
		int x = i * 2 + 1;
		if (x >= m->width -1) {
			luaL_error(L, "add wall (%d, %d) fail", x, y);
		}
		char c = wall[i];
		if (c >= 'A' && c<='Z') {
			int weight = (c - 'A' + 1);
			int v = 0;
			v |= map_set(m, x, y, weight);
			if (i > 0) {
				int w = map_get(m, x - 2, y);
				if (w != 0 && w != BLOCK_WEIGHT) {
					v |= map_set(m, x-1, y, weight);
				}
			}
			if (y > 0) {
				int w = map_get(m, x , y - 2);
				if (w != 0 && w != BLOCK_WEIGHT) {
					v |= map_set(m, x, y-1, weight);
				}
			}
			if (v != 0) {
				luaL_error(L, "add wall (%d, %d) fail", x, y);
			}
		}
	}
}

static int
lnewmap(lua_State *L) {
	luaL_checktype(L, 1, LUA_TTABLE);
	lua_settop(L, 1);
	int width = getfield(L, 0, "width");
	int height = getfield(L, 0, "height");
	width = width * 2 + 2;
	height = height * 2 + 2;
	struct map *m = lua_newuserdata(L, sizeof(struct map) + width * height * sizeof(m->m[0]));
	m->width = width;
	m->height = height;
	memset(m->m, 0, width * height * sizeof(m->m[0]));
	int i;
	for (i=0;i<width;i++) {
		map_set(m, i, 0, BLOCK_WEIGHT);
		map_set(m, i, height-1, BLOCK_WEIGHT);
	}
	for (i=1;i<height-1;i++) {
		map_set(m, 0, i, BLOCK_WEIGHT);
		map_set(m, width-1, i, BLOCK_WEIGHT);
	}
	i = 1;
	while (lua_geti(L, 1, i) == LUA_TTABLE) {
		int x = getfield(L, i, "x");
		int y = getfield(L, i, "y");
		int size = getfield(L, i, "size");
		lua_pop(L, 1);
		addbuilding(L, m, x, y, size);
		++i;
	}
	lua_pop(L, 1);
	if (lua_getfield(L, 1, "wall") == LUA_TTABLE) {
		int i = 1;
		while (lua_geti(L, -1, i) == LUA_TSTRING) {
			size_t sz;
			const char * wall = lua_tolstring(L, -1, &sz);
			addwall(L, m, i-1, wall, sz);
			lua_pop(L, 1);
			++i;
		}
		lua_pop(L, 1);
	}
	lua_pop(L, 1);
	return 1;
}

/*
   0  1  2 
    \ | /
  7 -   - 3
    / | \
   6  5  4
*/

static int
lblock(lua_State *L) {
	luaL_checktype(L, 1, LUA_TUSERDATA);
	struct map *m = lua_touserdata(L, 1);
	int x = luaL_checkinteger(L, 2);
	int y = luaL_checkinteger(L, 3);
	if (x < 0 || x >= m->width ||
		y < 0 || y >= m->height) {
		luaL_error(L, "Position (%d,%d) is out of map", x,y);
	}
	lua_pushinteger(L, map_get(m, x, y));

	return 1;
}

static inline int
distance(int x1, int y1, int x2, int y2) {
	int dx = x1 - x2;
	int dy = y1 - y2;
	if (dx < 0) {
		dx = -dx;
	}
	if (dy < 0) {
		dy = -dy;
	}
	if (dx < dy)
		return dx *  7 + (dy-dx) * 5;
	else
		return dy * 7 + (dx - dy) * 5;
}

struct context {
	struct path *P;
	int open;
	int closed;
	int n;
	int end_x;
	int end_y;
};

static struct pathnode *
add_open(struct context *ctx, int x, int y, int camefrom, int gscore) {
	struct path *P = ctx->P;
	if (ctx->n >= P->depth) {
		return NULL;
	}
	P->set[ctx->open++] = ctx->n;
	struct pathnode *pn = &P->n[ctx->n++];
	pn->x = x;
	pn->y = y;
	pn->camefrom = camefrom;
	pn->gscore = gscore;
	pn->fscore = gscore + distance(x,y,ctx->end_x,ctx->end_y);

	return pn;
};

static struct pathnode *
lowest_fscore(struct context *ctx) {
	int idx = 0;
	struct pathnode *pn = &ctx->P->n[ctx->P->set[idx]];
	int fscore = pn->fscore;
	int i;
	for (i=1;i<ctx->open;i++) {
		struct pathnode *tmp = &ctx->P->n[ctx->P->set[i]];
		if (tmp->fscore < fscore) {
			pn = tmp;
			idx = i;
			fscore = tmp->fscore;
		}
	}
	// remove from open set
	--ctx->open;
	if (idx != ctx->open) {
		ctx->P->set[idx] = ctx->P->set[ctx->open];
	}
	return pn;
}

static void
add_closed(struct context *ctx, int idx) {
	ctx->P->set[ctx->P->depth - 1 - ctx->closed++] = idx;
}

static int
in_closed(struct context *ctx, int x, int y) {
	int i;
	for (i=0;i<ctx->closed;i++) {
		int idx = ctx->P->set[ctx->P->depth - 1 - i];
		struct pathnode * pn = &ctx->P->n[idx];
		if (pn->x == x && pn->y == y)
			return 1;
	}
	return 0;
}

static struct pathnode *
find_open(struct context *ctx, int x, int y) {
	int i;
	for (i=0;i<ctx->open;i++) {
		int idx = ctx->P->set[i];
		struct pathnode * pn = &ctx->P->n[idx];
		if (pn->x == x && pn->y == y)
			return pn;
	}
	return NULL;
}

static int
nearest(struct path *P, int from, int to) {
	int ret = P->set[from];
	struct pathnode *pn = &P->n[ret];
	int fscore = pn->fscore;
	int i;
	for (i=from+1;i<to;i++) {
		int idx = P->set[i];
		pn = &P->n[idx];
		if (pn->fscore < fscore) {
			fscore = pn->fscore;
			ret = idx;
		}
	}
	return ret;
}

static struct {
	int dx;
	int dy;
	int distance;
} OFF[8] = {
	{ -1, -1, 7 },	// up-left
	{  0, -1, 5 },	// up
	{  1, -1, 7 },	// up-right
	{  1,  0, 5 },	// right
	{  1,  1, 7 },	// bottom-right
	{  0,  1, 5 },	// bottom
	{  -1, 1, 7 },	// bottom-left
	{  -1, 0, 5 },	// left
};

static int
path_finding(struct map *m, struct path *P, int start_x, int start_y, int end_x, int end_y) {
	struct context ctx;
	ctx.P = P;
	ctx.open = 0;
	ctx.closed = 0;
	ctx.n = 0;
	ctx.end_x = end_x;
	ctx.end_y = end_y;
	add_open(&ctx, start_x, start_y, -1, 0);
	while(ctx.open > 0) {
		struct pathnode * pn = lowest_fscore(&ctx);
		int current = pn - P->n;
		if (pn->x == end_x && pn->y == end_y)
			return current;
		add_closed(&ctx, current);
		int i;
		for (i=0;i<8;i++) {
			int x = pn->x + OFF[i].dx;
			int y = pn->y + OFF[i].dy;
			int weight = map_get(m, x, y);
			if (weight == BLOCK_WEIGHT)
				continue;
			if (in_closed(&ctx, x , y))
				continue;
			int tentative_gscore = pn->gscore + OFF[i].distance + OFF[i].distance * weight;
			struct pathnode * neighbor = find_open(&ctx, x, y);
			if (neighbor) {
				if (tentative_gscore < neighbor->gscore) {
					neighbor->camefrom = current;
					neighbor->gscore = tentative_gscore;
					neighbor->fscore = tentative_gscore + distance(x,y,end_x,end_y);
				}
			} else if (add_open(&ctx, x, y, current, tentative_gscore) == NULL) {
				break;
			}

		}
	}
	if (ctx.open > 0) {
		return nearest(P, 0, ctx.open);
	} else {
		return nearest(P, P->depth - ctx.closed, P->depth);
	}
}

static void
close_path(struct path *P) {
	if (P->depth > SEARCH_DEPTH) {
		free(P->set);
		free(P->n);
	}
}

static void
check_position(lua_State *L, struct map *m, int x, int y) {
	if (x < 0 || x >= m->width ||
		y < 0 || y >= m->height) {
		luaL_error(L, "Invalid position (%d,%d)", x,y);
	}
}

static int
lpath(lua_State *L) {
	luaL_checktype(L, 1, LUA_TUSERDATA);
	struct map *m = lua_touserdata(L, 1);
	int start_x = luaL_checkinteger(L, 2);
	int start_y = luaL_checkinteger(L, 3);
	int end_x = luaL_checkinteger(L, 4);
	int end_y = luaL_checkinteger(L, 5);

	check_position(L, m, start_x, start_y);
	check_position(L, m, end_x, end_y);

	struct path P;
	P.depth = luaL_optinteger(L, 6, 1024);
	int stack_size = P.depth > SEARCH_DEPTH ? 0 : P.depth;
	int set[stack_size];
	struct pathnode pn[stack_size];
	if (P.depth > SEARCH_DEPTH) {
		P.set = malloc(sizeof(int) * P.depth);
		P.n = malloc(sizeof(struct pathnode) * P.depth);
	} else {
		P.set = set;
		P.n = pn;
	}

	int node = path_finding(m, &P, start_x, start_y, end_x, end_y);
	int n = 1;
	int idx = node;
	while (P.n[idx].camefrom >= 0) {
		idx = P.n[idx].camefrom;
		++n;
	}

	struct {
		int x;
		int y;
	} pos[n];

	int i;

	for (i=0;i<n;i++) {
		struct pathnode *pn = &P.n[node];
		pos[i].x = pn->x;
		pos[i].y = pn->y;
		node = P.n[node].camefrom;
	}

	close_path(&P);

	lua_settop(L, 0);
	luaL_checkstack(L, n * 2, NULL);
	for (i=n-1;i>=0;i--) {
		lua_pushinteger(L, pos[i].x);
		lua_pushinteger(L, pos[i].y);
	}

	return n * 2;
}

struct map *
new_flowgraph(lua_State *L, struct map *m, int index) {
	if (lua_type(L, index) == LUA_TUSERDATA) {
		struct map * result = lua_touserdata(L, index);
		if (m->width == result->width && m->height == result->height) {
			return result;
		}
		lua_settop(L, index - 1);
	}
	struct map * result = lua_newuserdata(L, sizeof(struct map) + m->width * m->height * sizeof(m->m[0]));
	result->width = m->width;
	result->height = m->height;
	return result;
}

static inline void
target_init(struct map *m, int x, int y) {
	if (x < 0 || x >= m->width || y < 0 || y >=m->height)
		return;
	m->m[y * m->width + x] = 1;
}

static void
addtarget(lua_State *L, struct map *m, int x, int y, int size, int radius) {
	int i,j;
	radius += 1;
	int limit = radius * 2 + 1;
	limit *= limit;

	x = x * 2 + 1;
	y = y * 2 + 1;
	size = size * 2 - 1;
	for (i=1;i<=radius;i++) {
		for (j=1;j<=radius;j++) {
			int dist = (i*i+j*j) * 4;
			if (dist <= limit) {
				target_init(m, x-j, y-i);	// left-top
				target_init(m, x+size-1+j, y-i);	// right-top
				target_init(m, x-j, y+size-1+i);	// left-bottom
				target_init(m, x+size-1+j, y+size-1+i);	// right-bottom
			}
		}
	}
	for (i=y-radius;i<y+size+radius;i++) {
		if (i<0)
			continue;
		if (i>=m->height)
			break;
		for (j=x;j<x+size;j++) {
			if (j<0)
				continue;
			if (j>=m->width)
				break;
			m->m[i * m->width + j] = 1;
		}
	}
	for (i=y;i<y+size;i++) {
		if (i<0)
			continue;
		if (i>=m->height)
			break;
		for (j=0;j<radius;j++) {
			target_init(m, x - j - 1, i);
			target_init(m, x + size + j , i);
		}
	}
}

static struct route_queue *
create_queue(int n) {
	struct route_queue * q = malloc(sizeof(struct route_queue) + sizeof(q->q[0]) * n);
	q->head = 0;
	q->tail = 0;
	q->n = n;
	return q;
}

static void
enter_queue(struct route_queue *q, int x, int y) {
	struct route_coord *c = &q->q[q->tail];
	c->x = x;
	c->y = y;
	++q->tail;
	if (q->tail >= q->n)
		q->tail = 0;
	assert(q->head != q->tail);
}

static struct route_coord *
leave_queue(struct route_queue *q) {
	if (q->head == q->tail)
		return NULL;
	struct route_coord * c = &q->q[q->head];
	++q->head;
	if (q->head >= q->n)
		q->head = 0;
	return c;
}

static int
queue_exist(struct route_queue *q, int x, int y) {
	int head = q->head;
	while (head != q->tail) {
		struct route_coord * c = &q->q[head];
		if (c->x == x && c->y == y)
			return 1;
		++head;
		if (head > q->n)
			head = 0;
	}
	return 0;
}

static void
init_route(struct map * block, struct map *m, int *route, struct route_queue *q) {
	int width = m->width;
	int height = m->height;
	int i,j;
	for (i=0;i<height;i++) {
		for (j=0;j<height;j++) {
			int w = m->m[i * width + j];
			int b = block->m[i * width + j];
			if (w && b != BLOCK_WEIGHT) {
				route[i * width + j] = w + b * 5;
				enter_queue(q, j, i);
			}
		}
	}
}

static void
gen_route(struct map *m, int *route, struct route_queue *q) {
	struct route_coord *c = NULL;
	int width = m->width;
	while ((c=leave_queue(q))) {
		int weight = m->m[c->y * width + c->x];
		if (weight == BLOCK_WEIGHT)
			continue;
		int i;
		int odis = route[c->y * width + c->x];
		for (i=0;i<8;i++) {
			int x = c->x + OFF[i].dx;
			int y = c->y + OFF[i].dy;
			int dis = odis + OFF[i].distance +  m->m[y * width + x] * 5;
			int w = route[y * width + x];
			if (w == 0) {
				route[y * width + x] = dis;
				enter_queue(q, x, y);
			} else {
				if (w > dis) {
					route[y * width + x] = dis;
					if (!queue_exist(q, x, y)) {
						enter_queue(q, x, y);
					}
				}
			}
		}
	}
}

static void
convert_route(int *route, struct map *m) {
	int width = m->width;
	int height = m->height;
	int i,j;
	for (i=0;i<height;i++) {
		for (j=0;j<width;j++) {
			int w = route[i*width+j];
			int min_id = 0;
			if (w > 1) {
				int k;
				int min = w;
				for (k=0;k<8;k++) {
					int x = j + OFF[k].dx;
					int y = i + OFF[k].dy;
					int weight = route[y*width+x];
					if (weight > 0 && weight < min) {
						min = weight;
						min_id = k + 1;
					}
				}
			}
			m->m[i*width+j] = min_id;
		}
	}
}

/*
	userdata buildingmap
	table target {
		{ x = , y = , size = , radius = },
		...
	}
	userdata flowmap (optinal: result)

	return userdata flowmap
 */
static int
lflowgraph(lua_State *L) {
	luaL_checktype(L,1, LUA_TUSERDATA);
	struct map * m = lua_touserdata(L, 1);
	luaL_checktype(L,2, LUA_TTABLE);
	struct map * result = new_flowgraph(L, m, 3);
	int width = m->width;
	int height = m->height;
	memset(result->m, 0, width * height * sizeof(result->m[0]));
	int i = 1;
	while(lua_geti(L, 2, i) == LUA_TTABLE) {
		int x = getfield(L, i, "x");
		int y = getfield(L, i, "y");
		int size = getfield(L, i, "size");
		int radius = getfield(L, i, "radius");
		addtarget(L, result, x, y, size, radius);
		lua_pop(L, 1);
		++i;
	}
	lua_pop(L, 1);
	int *route = malloc(width * height * sizeof(int));
	struct route_queue *q = create_queue(width * height);
	init_route(m, result, route, q);
	gen_route(m, route, q);
	convert_route(route, result);
	free(route);
	free(q);

	return 1;
}

int
luaopen_pathfinding(lua_State *L) {
	luaL_checkversion(L);
	luaL_Reg l[] = {
		{ "new", lnewmap },
		{ "block", lblock },
		{ "path", lpath },
		{ "flowgraph", lflowgraph },
		{ NULL, NULL },
	};
	luaL_newlib(L,l);
	return 1;
}
