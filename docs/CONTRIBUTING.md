# Contributing to Directus Newsletter Feature

Thank you for your interest in contributing! This project helps agencies and developers add powerful newsletter functionality to Directus instances.

## Getting Started

### Prerequisites

- Node.js 16+ 
- Git
- Directus 11 instance for testing
- SendGrid account for email testing

### Development Setup

```bash
# 1. Fork and clone the repository
git clone https://github.com/yourusername/directus-newsletter-installer.git
cd directus-newsletter-installer

# 2. Install dependencies
npm install

# 3. Set up test environment
cp .env.example .env.test
# Edit .env.test with your test Directus credentials

# 4. Run validation tests
npm run validate
```

## Project Structure

```
directus-newsletter-installer/
├── deploy.sh                    # Main deployment script
├── newsletter-installer.js      # Node.js installer
├── server/                      # Nuxt server endpoints
│   └── api/newsletter/
├── docs/                        # Documentation
├── examples/                    # Configuration examples
├── scripts/                     # Utility scripts
└── types/                       # TypeScript definitions
```

## How to Contribute

### Reporting Issues

Before creating an issue:

1. **Search existing issues** to avoid duplicates
2. **Use the issue template** for bug reports
3. **Include debug information**:
   - Environment details (OS, Node.js version, Docker)
   - Error messages and logs
   - Steps to reproduce
   - Expected vs actual behavior

### Suggesting Features

For feature requests:

1. **Check the roadmap** to see if it's already planned
2. **Describe the use case** - what problem does it solve?
3. **Provide examples** of how it would work
4. **Consider implementation** - is it technically feasible?

### Contributing Code

#### 1. Create a Branch

```bash
# Create feature branch
git checkout -b feature/new-block-type

# Or bug fix branch
git checkout -b fix/mjml-compilation-error
```

#### 2. Development Guidelines

**Code Style:**
- Use ESLint configuration
- Follow existing code patterns
- Add comments for complex logic
- Use meaningful variable names

**Commit Messages:**
```bash
# Format: type(scope): description
git commit -m "feat(blocks): add quote block type"
git commit -m "fix(mjml): handle malformed templates"
git commit -m "docs: update installation guide"
```

**Testing:**
```bash
# Test installer script
npm run validate

# Test with actual Directus instance
./deploy.sh setup
./deploy.sh install https://test-directus.com admin@test.com password

# Test endpoints manually
curl -X POST http://localhost:3000/api/newsletter/compile-mjml \
  -H "Content-Type: application/json" \
  -d '{"newsletter_id": 1}'
```

#### 3. Submit Pull Request

1. **Update documentation** if needed
2. **Add tests** for new functionality
3. **Update CHANGELOG.md**
4. **Create detailed PR description**

Pull Request Template:
```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Performance improvement

## Testing
- [ ] Tested on development environment
- [ ] Tested on staging environment
- [ ] Manual testing completed
- [ ] No breaking changes

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] No merge conflicts
```

## Development Areas

### Adding New Block Types

To contribute a new MJML block type:

```javascript
// Example: Video Block
{
  name: "Video Block",
  slug: "video",
  description: "Embedded video with poster image",
  mjml_template: `
    <mj-section background-color="{{background_color}}" padding="{{padding}}">
      <mj-column>
        {{#if poster_image}}
        <mj-image src="{{poster_image}}" alt="{{video_title}}" href="{{video_url}}" />
        {{/if}}
        <mj-text align="center" font-size="16px" padding="10px 0">
          <a href="{{video_url}}" style="color: #007bff;">▶️ {{video_title}}</a>
        </mj-text>
        {{#if description}}
        <mj-text align="center" font-size="14px" color="#666666">
          {{description}}
        </mj-text>
        {{/if}}
      </mj-column>
    </mj-section>
  `,
  fields_schema: {
    type: "object",
    properties: {
      video_title: { type: "string", title: "Video Title" },
      video_url: { type: "string", title: "Video URL" },
      poster_image: { type: "string", title: "Poster Image URL" },
      description: { type: "string", title: "Description" },
      background_color: { type: "string", title: "Background Color", default: "#ffffff" },
      padding: { type: "string", title: "Padding", default: "20px 0" }
    },
    required: ["video_title", "video_url"]
  },
  status: "published"
}
```

### Improving Installation Process

Areas for improvement:
- Better error handling and recovery
- Support for more database types
- Automated flow configuration
- Configuration validation
- Multi-language support

### Enhancing Server Endpoints

Potential improvements:
- Email template caching
- Batch processing optimization
- Advanced personalization
- A/B testing support
- Analytics integration

## Documentation Guidelines

### Writing Style

- **Clear and concise** - avoid jargon
- **Step-by-step instructions** with code examples
- **Screenshots** for UI-related documentation
- **Cross-references** to related sections
- **Update dates** for time-sensitive information

### Documentation Types

1. **Installation docs** - Step-by-step setup
2. **API documentation** - Endpoint references
3. **Troubleshooting** - Common issues and solutions
4. **Examples** - Real-world use cases
5. **Architecture** - Technical implementation details

## Testing Guidelines

### Manual Testing Checklist

Before submitting PRs, test:

- [ ] **Installation** on fresh Directus instance
- [ ] **Block creation** and editing
- [ ] **MJML compilation** with various blocks
- [ ] **Email sending** to test addresses
- [ ] **Flow execution** from Directus admin
- [ ] **Error handling** with invalid data
- [ ] **Rollback process** if applicable

### Test Environments

Set up multiple test environments:

1. **Development** - Local Docker setup
2. **Staging** - Production-like environment
3. **Integration** - Test with real SendGrid/email services

## Release Process

### Version Numbering

We follow [Semantic Versioning](https://semver.org/):
- **MAJOR.MINOR.PATCH** (e.g., 1.2.3)
- **Major** - Breaking changes
- **Minor** - New features (backward compatible)
- **Patch** - Bug fixes

### Release Checklist

1. Update version in `package.json`
2. Update `CHANGELOG.md`
3. Test installation on clean environment
4. Create GitHub release with notes
5. Update documentation if needed

## Community Guidelines

### Code of Conduct

- **Be respectful** and inclusive
- **Help others** learn and contribute
- **Give constructive feedback**
- **Credit contributors** appropriately

### Communication

- **GitHub Issues** - Bug reports and feature requests
- **GitHub Discussions** - General questions and ideas
- **Email** - Private/security concerns

## Recognition

Contributors are recognized in:
- `CONTRIBUTORS.md` file
- GitHub contributors section
- Release notes for significant contributions
- Project documentation

## Need Help?

- 📖 **Documentation**: [Installation Guide](docs/INSTALLATION.md)
- 🐛 **Issues**: [GitHub Issues](https://github.com/yourusername/directus-newsletter-installer/issues)
- 💬 **Discussions**: [GitHub Discussions](https://github.com/yourusername/directus-newsletter-installer/discussions)
- 📧 **Email**: support@youragency.com

Thank you for contributing to make newsletter management better for the Directus community! 🚀