module.exports = async function (req, res) {
  console.log("This is home");

  const allPosts = await Post.find()
  res.view('pages/home',
    {allPosts}
    );
}
