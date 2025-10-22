# NutriCare App - GitHub Pages Deployment Guide

This guide will help you deploy your Flutter web app to GitHub Pages with a custom domain.

## Prerequisites

1. A GitHub account
2. A custom domain (optional but recommended)
3. Flutter SDK installed locally

## Step 1: Create GitHub Repository

1. Go to [GitHub](https://github.com) and create a new repository
2. Name it `nutricare-app` (or your preferred name)
3. Make it public (required for free GitHub Pages)
4. Don't initialize with README, .gitignore, or license (we already have files)

## Step 2: Push Your Code to GitHub

```bash
# Initialize git repository (if not already done)
git init

# Add all files
git add .

# Commit your changes
git commit -m "Initial commit: NutriCare Flutter web app"

# Add your GitHub repository as remote
git remote add origin https://github.com/YOUR_USERNAME/nutricare-app.git

# Push to GitHub
git push -u origin main
```

## Step 3: Enable GitHub Pages

1. Go to your repository on GitHub
2. Click on **Settings** tab
3. Scroll down to **Pages** section
4. Under **Source**, select **GitHub Actions**
5. Save the settings

## Step 4: Configure Custom Domain (Optional)

### Option A: Using a Subdomain (Free)
- Use GitHub's free subdomain: `YOUR_USERNAME.github.io/nutricare-app`
- No additional configuration needed

### Option B: Using a Custom Domain
1. **Purchase a domain** from providers like:
   - Namecheap
   - GoDaddy
   - Google Domains
   - Cloudflare

2. **Configure DNS**:
   - Add a CNAME record pointing to `YOUR_USERNAME.github.io`
   - Or add A records pointing to GitHub's IP addresses:
     - 185.199.108.153
     - 185.199.109.153
     - 185.199.110.153
     - 185.199.111.153

3. **Update the workflow file**:
   - Edit `.github/workflows/deploy.yml`
   - Replace `nutricare-app.com` with your actual domain
   - Update the `CNAME` file with your domain

## Step 5: Automatic Deployment

The GitHub Actions workflow will automatically:
1. Build your Flutter web app
2. Deploy it to GitHub Pages
3. Configure your custom domain

## Step 6: Verify Deployment

1. Wait for the GitHub Actions workflow to complete (check the Actions tab)
2. Visit your deployed app:
   - Free subdomain: `https://YOUR_USERNAME.github.io/nutricare-app`
   - Custom domain: `https://your-domain.com`

## Troubleshooting

### Common Issues:

1. **Build fails**: Check Flutter version compatibility
2. **404 errors**: Ensure base-href is correctly set
3. **Custom domain not working**: Verify DNS settings and wait for propagation (up to 24 hours)

### Manual Deployment (if needed):

```bash
# Build the web app
flutter build web --release --base-href "/nutricare-app/"

# The built files will be in build/web/
# You can manually upload these to GitHub Pages
```

## Security Considerations

1. **Environment Variables**: Never commit API keys or secrets to the repository
2. **Firebase Configuration**: Ensure your Firebase project allows your domain
3. **CORS**: Configure your backend to allow requests from your domain

## Performance Optimization

1. **Enable Gzip compression** on your web server
2. **Use a CDN** for faster global access
3. **Optimize images** before adding to assets
4. **Enable caching** for static assets

## Monitoring

1. **GitHub Actions**: Monitor build status in the Actions tab
2. **GitHub Pages**: Check deployment status in Settings > Pages
3. **Custom Domain**: Use tools like `dig` or online DNS checkers

## Support

If you encounter issues:
1. Check GitHub Actions logs
2. Verify DNS configuration
3. Ensure all files are committed
4. Check Flutter web compatibility

---

**Note**: Replace `YOUR_USERNAME` and `nutricare-app` with your actual GitHub username and repository name throughout this guide.
