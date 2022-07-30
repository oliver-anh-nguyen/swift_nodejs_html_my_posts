module.exports = {
  posts: function (req, res) {
    Post.find().exec(function (err, data) {
      if (err) {
        return res.serverError(err.toString());
      }
      res.send(data);
    })
  },

  create: function (req, res) {
    const {title, body} = req.body;
    Post.create({title: title, body: body}).exec(function (err) {
      if (err) {
        return res.serverError(err.toString());
      }
      return res.end();
    });
  },

  findById: function (req, res) {
    const {postId} = req.params;
    const post = allPosts.find(p => p.id == postId);
    if (!post) {
      res.json({error: `Not found postId: ${postId}`});
    }
    res.json(post);
  },

  delete: async function (req, res) {
    const { postId } = req.params;
    await Post.destroy({id: postId});
    res.end('Finished deleting post')
  }
}
